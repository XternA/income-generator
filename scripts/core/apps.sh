#!/bin/sh

[ -n "$__CORE_APPS_CACHED" ] && return
__CORE_APPS_CACHED=1

. scripts/core/common.sh

CORE_get_app_totals() {
    if [ -z "$CORE_TOTAL_APPS" ] || [ -z "$CORE_TOTAL_SERVICES" ]; then
        _totals=$(jq -r 'length as $total | map(select(has("service_enabled"))) | length as $services | "\($total) \($services)"' "$JSON_FILE")
        CORE_TOTAL_APPS=${_totals%% *}
        CORE_TOTAL_SERVICES=${_totals##* }
    fi
}

CORE_get_app_properties_index() {
    if [ -z "$CORE_APP_PROPERTIES_INDEX" ]; then
        CORE_APP_PROPERTIES_INDEX=$(jq -r '.[] | select(.properties != null) | "\(.name)=\(.properties | map(ltrimstr("#")) | join(" "))"' "$JSON_FILE")
    fi
}

CORE_get_app_totals
CORE_get_app_properties_index

__core_build_field_mapping() {
    _mapping=""
    _separator=""

    for arg; do
        _field="${arg%%:*}"
        _type="${arg#*:}"
        [ "$_field" = "$_type" ] && _type="string"
        _field="${_field#.}"

        if [ "$_type" = "array" ]; then
            _mapping="$_mapping$_separator\"${_field}=\" + ((.${_field} // []) | join(\" \") | @sh)"
        else
            _mapping="$_mapping$_separator\"${_field}=\" + ((.${_field} // \"\") | @sh)"
        fi
        _separator=","
    done
    echo "$_mapping"
}

CORE_extract_all_app_data() {
    jq -r ".[] | \"\(.name) $(printf ' \(%s)' "$@")\"" "$JSON_FILE"
}

CORE_extract_app_data() {
    _filter=".is_enabled == true"

    for f in "$@"; do
        if [ "$f" = ".service_enabled" ]; then
            _filter="(.is_enabled == true or .service_enabled == true)"
            break
        fi
    done

    jq -r ".[] | select($_filter) | \"\(.name) $(printf ' \(%s)' "$@")\"" "$JSON_FILE"
}

CORE_extract_app_data_fields_only() {
    _app_name="$1"
    shift

    if [ $# -gt 0 ]; then
        _field_expr=""
        for _field in "$@"; do
            _field_expr="$_field_expr$_field // \"null\" ,"
        done
        _field_expr=${_field_expr%,}

        jq -r --arg app "$_app_name" ".[] | select(.name==\$app) | [$_field_expr] | join(\" \")" "$JSON_FILE"
    fi
}

CORE_extract_app_data_field() {
    _field_name="$1"
    jq -r ".[] | select(has(\"$_field_name\")) | \"\(.name) \(.$_field_name)\"" "$JSON_FILE"
}

CORE_extract_and_map_app_data() {
    _filter=".is_enabled == true"

    for f in "$@"; do
        if [ "$f" = ".service_enabled" ]; then
            _filter="(.is_enabled == true or .service_enabled == true)"
            break
        fi
    done

    _mapping=$(__core_build_field_mapping "$@")
    jq -r ".[] | select($_filter) | [ $_mapping ] | join(\" \")" "$JSON_FILE"
}

CORE_extract_and_map_single_app() {
    _app_name="$1"
    shift

    _mapping=$(__core_build_field_mapping "$@")
    jq -r --arg app "$_app_name" ".[] | select(.name==\$app) | [ $_mapping ] | join(\" \")" "$JSON_FILE"
}

CORE_export_selection() {
    _target="$1"

    _raw=$(jq -r '.[] |
        "\(.name) " +
        (if .is_enabled then "ENABLED" else "DISABLED" end) + " " +
        (if .service_enabled != null then
            if .service_enabled then "ENABLED" else "DISABLED" end
        else
            "null"
        end)
    ' "$JSON_FILE" 2>/dev/null) || return 1
    [ -n "$_raw" ] || return 1

    _content=$(printf '%s\n' "$_raw" | while IFS=' ' read -r _name _state _service; do
        printf '%s=%s\n' "$_name" "$_state"
        [ "$_service" != "null" ] && printf '%s_SERVICE=%s\n' "$_name" "$_service"
    done)

    if [ -f "$_target" ] && [ "$_content" = "$(cat "$_target" 2>/dev/null)" ]; then
        return 0
    fi

    _tmp="$_target.tmp.$$"
    printf '%s\n' "$_content" > "$_tmp" || { rm -f "$_tmp"; return 1; }
    mv "$_tmp" "$_target" || { rm -f "$_tmp"; return 1; }
}

CORE_selection_filter() {
    _source="$1"
    [ -f "$_source" ] || return 1

    _jq_filter="."
    while IFS='=' read -r _name _state; do
        case "$_name" in
            "") continue ;;
        esac
        _app_enabled="false"
        [ "$_state" = "ENABLED" ] && _app_enabled="true"

        if [ "${_name#*_SERVICE}" != "$_name" ]; then
            _jq_filter="$_jq_filter | (.[] | select(.name == \"${_name%_SERVICE}\").service_enabled) = $_app_enabled"
        else
            _jq_filter="$_jq_filter | (.[] | select(.name == \"$_name\").is_enabled) = $_app_enabled"
        fi
    done < "$_source"

    printf '%s' "$_jq_filter"
}

CORE_import_selection() {
    _source="$1"
    [ -f "$_source" ] || return

    _jq_filter=$(CORE_selection_filter "$_source") || return 1

    _current=$(jq -c '.' "$JSON_FILE" 2>/dev/null) || return 1
    _updated=$(jq -c "$_jq_filter" "$JSON_FILE" 2>/dev/null) || return 1
    [ "$_current" = "$_updated" ] && return 0

    CORE_write_json "$JSON_FILE" "$_jq_filter" || return 1
}

