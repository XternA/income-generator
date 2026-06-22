#!/bin/sh

[ -n "$__PROXY_UUID_GENERATOR_CACHED" ] && return
__PROXY_UUID_GENERATOR_CACHED=1

. scripts/util/uuid-generator.sh
. scripts/core/proxy.sh

export PROXY_FOLDER="$CORE_PROXY_FOLDER"
export PROXY_FOLDER_ACTIVE="$CORE_PROXY_FOLDER_ACTIVE"
TOTAL_PROXIES="$CORE_TOTAL_PROXIES"
ACTIVE_PROXIES="$CORE_ACTIVE_PROXIES"

generate_uuid_files() { CORE_generate_uuid_files; }

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
                printf " ${GREEN}-> ${YELLOW}%s${NC}\n" "$line"
            done < "$file"
            printf "${NC}\n"
        done
        return
    fi
}

get_proxy_file() { CORE_get_proxy_file "$@"; }

export_active_uuid() { CORE_export_active_uuid "$@"; }
