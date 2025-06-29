#!/bin/sh

. scripts/util/uuid-generator.sh

export PROXY_FOLDER="${ROOT_DIR}/proxy_uuid"
export PROXY_FOLDER_ACTIVE="$PROXY_FOLDER/active"
TOTAL_PROXIES="$(awk 'BEGIN {count=0} NF {count++} END {print count}' "$PROXY_FILE")"

generate_uuid_files() {
    app_data="jq -r '.[] | select(.is_enabled == true and .uuid_type != null) | \"\(.name) \(.uuid_type)\"' \"$JSON_FILE\""

    [ -d "$PROXY_FOLDER" ] || mkdir -p "$PROXY_FOLDER_ACTIVE"

    counter=1
    while true; do
        echo "$(eval $app_data)" | while read -r name uuid_type; do
            proxy_file="${PROXY_FOLDER}/${name}.uuid"
            uuid="$(generate_uuid "$uuid_type")"

            if [ -f "$proxy_file" ]; then
                current_uuid_count="$(awk 'BEGIN {count=0} NF {count++} END {print count}' "$proxy_file")"
                [ "$current_uuid_count" -lt "$TOTAL_PROXIES" ] && printf "${uuid}\n" >> "$proxy_file"
            else
                printf "${uuid}\n" > "$proxy_file"
            fi
        done

        [ "$counter" -ge "$TOTAL_PROXIES" ] && break || counter=$((counter + 1))
    done
}

view_proxy_uuids() {
    if [ "$1" = "all" ]; then
        for file in "$PROXY_FOLDER"/*; do
            [ -f "$file" ] || continue

            filename="${file##*/}"
            app_name="${filename%%.*}" # Remove extension

            echo "[ ${RED}${app_name}${NC} ]${NC}"
            counter=0
            while IFS= read -r line; do
                [ $(( counter % 2 )) -eq 0 ] && echo "${YELLOW}$line" || echo "${BLUE}$line"
                counter=$((counter + 1))
            done < "$file"
            echo "$NC"
        done
        return
    fi

    echo "Active Proxies: ${RED}${TOTAL_PROXIES}${NC}\n"

    if [ "$1" = "active" ]; then
        app_data=$(jq -r '.[] | select(.is_enabled == true and .proxy_uuid != null) | "\(.name) \(.proxy_uuid.description)"' "$JSON_FILE")

        [ -z "$app_data" ] && echo "No active application with multi-UUID currently in use.\n" && return

        echo "$app_data" | while read -r name description; do
            file="${PROXY_FOLDER_ACTIVE}/${name}.uuid"

            [ -f "$file" ] || continue

            echo "[ ${GREEN}${name}${NC} ]${NC}"
            [ "$description" != null ] && echo "${PINK}$description${NC}\n"

            while IFS= read -r line; do
                echo " ${GREEN}-> ${YELLOW}$line${NC}"
            done < "$file"
            echo "$NC"
        done
        return
    fi
}

get_proxy_file() {
    local app_name="$1"
    [ -f "${PROXY_FOLDER}/${app_name}.uuid" ] && echo "${PROXY_FOLDER}/${app_name}.uuid"
}

export_active_uuid() {
    local uuid="$1"
    local app_name="$2"
    
    [ -d "$PROXY_FOLDER_ACTIVE" ] || mkdir -p "$PROXY_FOLDER_ACTIVE"
    echo "$uuid" >> "$PROXY_FOLDER_ACTIVE/${app_name}.uuid"
}
