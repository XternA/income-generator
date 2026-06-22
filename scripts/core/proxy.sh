#!/bin/sh

[ -n "$__CORE_PROXY_CACHED" ] && return
__CORE_PROXY_CACHED=1

. scripts/core/common.sh
. scripts/core/apps.sh

CORE_PROXY_FOLDER="${IGM_HOME}/proxy_uuid"
CORE_PROXY_FOLDER_ACTIVE="$CORE_PROXY_FOLDER/active"

CORE_get_proxy_counts() {
    if [ -f "$PROXY_FILE" ]; then
        read CORE_TOTAL_PROXIES CORE_ACTIVE_PROXIES <<EOF2
$(awk 'NF {total++} /^[^#]/ && NF {active++} END {print total+0, active+0}' "$PROXY_FILE" 2>/dev/null)
EOF2
    else
        CORE_TOTAL_PROXIES=0
        CORE_ACTIVE_PROXIES=0
    fi
}

CORE_generate_uuid_files() {
    . scripts/util/uuid-generator.sh

    _app_data=$(jq -r '.[] | select(.is_enabled == true and .uuid_type != null) | "\(.name) \(.uuid_type)"' "$JSON_FILE")
    [ -z "$_app_data" ] && return

    [ -d "$CORE_PROXY_FOLDER" ] || mkdir -p "$CORE_PROXY_FOLDER_ACTIVE"

    echo "$_app_data" | while IFS=' ' read -r name uuid_type; do
        _proxy_file="${CORE_PROXY_FOLDER}/${name}.uuid"
        _existing_count=$(awk 'NF {n++} END {print n+0}' "$_proxy_file" 2>/dev/null)
        _proxies_needed=$((CORE_TOTAL_PROXIES - _existing_count))

        [ "$_proxies_needed" -le 0 ] && continue
        generate_uuid_batch "$_proxies_needed" "$uuid_type" >> "$_proxy_file"
    done
}

CORE_get_proxy_file() {
    [ -f "${CORE_PROXY_FOLDER}/${1}.uuid" ] && echo "${CORE_PROXY_FOLDER}/${1}.uuid"
}

CORE_export_active_uuid() {
    [ -d "$CORE_PROXY_FOLDER_ACTIVE" ] || mkdir -p "$CORE_PROXY_FOLDER_ACTIVE"
    echo "$1" >> "$CORE_PROXY_FOLDER_ACTIVE/${2}.uuid"
}

CORE_load_limit_data() {
    limit_data=$(awk -F= '{print $1, $2}' "$PROXY_INSTALL_LIMIT")
}

CORE_populate_proxy_limits() {
    if [ ! -f "$PROXY_INSTALL_LIMIT" ]; then
        CORE_extract_all_app_data .install_limit | awk '{ val = ($2=="null"?"-":$2); print $1 "=" val }' > "$PROXY_INSTALL_LIMIT"
    else
        _tmp_file=$(mktemp)
        _tmp_source=$(mktemp)

        CORE_extract_all_app_data .install_limit | awk '{print $1, $2}' > "$_tmp_source"

        awk '
            BEGIN { OFS="=" }
            FNR==NR { split($0, a, "="); old[a[1]]=a[2]; next }
            {
                key = $1
                val = ($2 == "null" ? "-" : $2)
                if (key in old) { print key, old[key] }
                else { print key, val }
            }
        ' "$PROXY_INSTALL_LIMIT" "$_tmp_source" > "$_tmp_file"

        mv "$_tmp_file" "$PROXY_INSTALL_LIMIT"
        rm -f "$_tmp_source"
    fi
    CORE_load_limit_data
}

CORE_get_app_install_limit() {
    _search_app="$1"
    set -- $limit_data

    _search_uc=$(printf '%s' "$_search_app" | tr '[:lower:]' '[:upper:]')

    while [ $# -gt 0 ]; do
        _app_uc=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
        if [ "$_app_uc" = "$_search_uc" ]; then
            case "$2" in
                ""|-) echo "null" ;;
                *) echo "$2" ;;
            esac
            return 0
        fi
        shift 2
    done
    echo "null"
}





CORE_get_proxy_counts
CORE_populate_proxy_limits
