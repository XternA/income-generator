#!/bin/sh

. "${ROOT_DIR}/scripts/util/uuid-generator.sh"

TOTAL_PROXIES="$(awk 'BEGIN {count=0} NF {count++} END {print count}' "$PROXY_FILE")"

generate_uuid_file() {
    app_data="jq -r '.[] | select(.is_enabled == true and .proxy_uuid != null) | \"\(.name) \(.proxy_uuid)\"' \"$JSON_FILE\""
    folder_dir="${ROOT_DIR}/proxy_uuid"

    [ -n "$folder_dir" ] && mkdir -p "$folder_dir"

    counter=2 # Start from two as standard will already count as one UUID.
    while true; do
        echo "$(eval $app_data)" | while read -r name proxy_uuid; do
            requires_uuid=$(echo "$proxy_uuid" | jq -r '.requires_uuid')
            uuid_type=$(echo "$proxy_uuid" | jq -r '.uuid_type')

            proxy_file="${folder_dir}/${name}.uuid"
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
