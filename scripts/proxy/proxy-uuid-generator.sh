#!/bin/sh

. "${ROOT_DIR}/scripts/util/uuid-generator.sh"

export PROXY_FOLDER="${ROOT_DIR}/proxy_uuid"
TOTAL_PROXIES="$(awk 'BEGIN {count=0} NF {count++} END {print count}' "$PROXY_FILE")"

generate_uuid_files() {
    app_data="jq -r '.[] | select(.is_enabled == true and .proxy_uuid != null) | \"\(.name) \(.proxy_uuid)\"' \"$JSON_FILE\""

    [ -n "$PROXY_FOLDER" ] && mkdir -p "$PROXY_FOLDER"

    counter=1
    while true; do
        echo "$(eval $app_data)" | while read -r name proxy_uuid; do
            requires_uuid=$(echo "$proxy_uuid" | jq -r '.requires_uuid')
            uuid_type=$(echo "$proxy_uuid" | jq -r '.uuid_type')

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

    echo "Running Proxies: ${RED}${TOTAL_PROXIES}${NC}\n"

    for file in "$PROXY_FOLDER"/*; do
        [ -f "$file" ] || continue

        filename="${file##*/}"
        app_name="${filename%%.*}" # Remove extension
        description=$(jq -r --arg name "${app_name}" '.[] | select(.name == $name and .proxy_uuid != null) | .proxy_uuid.description' "$JSON_FILE")

        echo "[ ${RED}${app_name}${NC} ]${NC}"
        [ "$description" != null ] && echo " ${GREEN}->${NC} $description\n"

        counter=0
        while IFS= read -r line; do
            [ $counter -lt $TOTAL_PROXIES ] || continue # List in-use ID's corresponding to proxy count
            [ $(( counter % 2 )) -eq 0 ] && echo "${YELLOW}$line" || echo "${BLUE}$line"
            counter=$((counter + 1))
        done < "$file"
        echo "$NC"
    done
}

get_proxy_file() {
    local app_name="$1"
    [ -f "${PROXY_FOLDER}/${app_name}.uuid" ] && echo "${PROXY_FOLDER}/${app_name}.uuid"
}
