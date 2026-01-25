#!/bin/sh

[ -n "$__PROXY_UUID_GENERATOR_CACHED" ] && return
__PROXY_UUID_GENERATOR_CACHED=1

. scripts/util/uuid-generator.sh

export PROXY_FOLDER="${ROOT_DIR}/proxy_uuid"
export PROXY_FOLDER_ACTIVE="$PROXY_FOLDER/active"

if [ -f "$PROXY_FILE" ]; then
    read TOTAL_PROXIES ACTIVE_PROXIES <<EOF
$(awk 'END {print NR, active+0} /^[^#]/ && NF {active++}' "$PROXY_FILE" 2>/dev/null)
EOF
else
    TOTAL_PROXIES=0
    ACTIVE_PROXIES=0
fi

generate_uuid_files() {
    app_data=$(jq -r '.[] | select(.is_enabled == true and .uuid_type != null) | "\(.name) \(.uuid_type)"' "$JSON_FILE")
    [ -z "$app_data" ] && return

    [ -d "$PROXY_FOLDER" ] || mkdir -p "$PROXY_FOLDER_ACTIVE"

    echo "$app_data" | while IFS=' ' read -r name uuid_type; do
        proxy_file="${PROXY_FOLDER}/${name}.uuid"

        existing_count=$(awk 'NF {n++} END {print n+0}' "$proxy_file" 2>/dev/null)
        proxies_needed=$((TOTAL_PROXIES - existing_count))

        [ "$proxies_needed" -le 0 ] && continue

        # Generate all needed UUIDs in batch
        counter=0
        while [ "$counter" -lt "$proxies_needed" ]; do
            generate_uuid "$uuid_type"
            counter=$((counter + 1))
        done >> "$proxy_file"
    done
}

view_proxy_uuids() {
    if [ "$1" = "all" ]; then
        for file in "$PROXY_FOLDER"/*; do
            [ -f "$file" ] || continue

            filename="${file##*/}"
            app_name="${filename%%.*}" # Remove extension

            printf "[ ${RED}${app_name}${NC} ]${NC}\n"
            awk -v yellow="$YELLOW" -v blue="$BLUE" -v nc="$NC" '{ printf "%s%s%s\n", (NR % 2 ? yellow : blue), $0, nc }' "$file"
            printf "${NC}\n"
        done
        return
    fi

    printf "Active Proxies: ${RED}${ACTIVE_PROXIES}${NC}\n\n"
    if [ "$1" = "active" ]; then
        app_data=$(jq -r '.[] | select(.is_enabled == true and .proxy_uuid != null) | "\(.name) \(.proxy_uuid.description)"' "$JSON_FILE")

        [ -z "$app_data" ] && printf "No active application with multi-UUID currently in use.\n\n" && return

        echo "$app_data" | while read -r name description; do
            file="${PROXY_FOLDER_ACTIVE}/${name}.uuid"

            [ -f "$file" ] || continue

            printf "[ ${GREEN}${name}${NC} ]${NC}\n"
            [ "$description" != null ] && printf "%b%s%b\n\n" "${PINK}" "$description" "${NC}"

            while IFS= read -r line; do
                echo " ${GREEN}-> ${YELLOW}$line${NC}"
            done < "$file"
            echo "$NC"
        done
        return
    fi
}

get_proxy_file() {
    app_name="$1"
    [ -f "${PROXY_FOLDER}/${app_name}.uuid" ] && echo "${PROXY_FOLDER}/${app_name}.uuid"
}

export_active_uuid() {
    uuid="$1"
    app_name="$2"

    [ -d "$PROXY_FOLDER_ACTIVE" ] || mkdir -p "$PROXY_FOLDER_ACTIVE"
    echo "$uuid" >> "$PROXY_FOLDER_ACTIVE/${app_name}.uuid"
}
