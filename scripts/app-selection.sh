#!/bin/sh

display_banner() {
    clear
    echo "Income Generator Application Manager"
    echo "${GREEN}----------------------------------------${NC}\n"
}

choose_application_type() {
    display_banner

    if [ "$1" = "service" ]; then
        field="service_enabled"
        type="Service"
        action="service"
        other="applications"
        shortcut="a"
    else
        field="is_enabled"
        type="App"
        action="application"
        other="services"
        shortcut="s"
    fi

    display_table_choice "$field" "$type" "$action" "$shortcut" "$other"
}

display_table_choice() {
    local field_name="$1"
    local header="$2"
    local prompt="$3"
    local type=$4
    local type_prompt=$5

    json_content=$(cat "$JSON_FILE")
    app_data=$(echo "$json_content" | jq -r ".[] | select(has(\"$field_name\")) | \"\(.name) \(.${field_name})\"")

    echo "${RED}Disabled${NC} ${prompt}s will not be deployed.\n"

    printf "%-4s %-21s %-8s\n" "No." "$header Name" "Status"
    printf "%-4s %-21s %-8s\n" "---" "--------------------" "--------"

    counter=1
    echo "$app_data" | while IFS=' ' read -r name is_enabled; do
        if [ "$is_enabled" = "true" ]; then
            status="${GREEN}Enabled${NC}"
        else
            status="${RED}Disabled${NC}"
        fi

        printf "%-4s %-21s %b\n" "$counter" "$name" "$status"
        counter=$((counter + 1))
    done

    echo "\nOptions:"
    echo "  ${GREEN}e${NC} = ${GREEN}enable all${NC}"
    echo "  ${RED}d${NC} = ${RED}disable all${NC}"
    echo "  ${YELLOW}${type}${NC} = ${YELLOW}select ${type_prompt}${NC}"
    echo "  ${BLUE}0${NC} = ${BLUE}exit${NC}"

    printf "\nSelect to ${GREEN}enable${NC} | ${RED}disable${NC} $prompt (1-%s): " "$(echo "$app_data" | wc -l | xargs)"
    read -r choice

    case $choice in
        [1-9]*)
            # Enable or disable specific application
            if ! [ "$choice" -ge 1 ] || ! [ "$choice" -le "$(echo "$app_data" | wc -l)" ]; then
                echo "\nInvalid input! Please enter a number between 1 and $(echo "$app_data" | wc -l)."
                printf "\nPress Enter to continue..."; read input
            else
                # Update entry
                chosen_app=$(echo "$app_data" | sed -n "${choice}p" | cut -d' ' -f1)
                updated_json_content=$(jq --indent 4 --arg chosen_app "$chosen_app" --arg field_name "$field_name" '. |= map(if .name == $chosen_app then .[$field_name] |= not else . end)' "$JSON_FILE")
                echo "$updated_json_content" > "$JSON_FILE"
            fi
            ;;
        e)
            # Enable all
            updated_json_content=$(jq --indent 4 --arg field_name "$field_name" 'map(if has($field_name) then .[$field_name] = true else . end)' "$JSON_FILE")
            echo "$updated_json_content" > "$JSON_FILE"
            ;;
        d)
            # Disable all
            updated_json_content=$(jq --indent 4 --arg field_name "$field_name" 'map(if has($field_name) then .[$field_name] = false else . end)' "$JSON_FILE")
            echo "$updated_json_content" > "$JSON_FILE"
            ;;
        a|s)
            if [ "$choice" = "s" ]; then
                choose_application_type service
            else
                choose_application_type
            fi
            ;;
        0)
            export_selection
            exit 0
            ;;
        *)
            echo "\nInvalid option! Please select a valid option."
            printf "\nPress Enter to continue..."; read input
            ;;
    esac
}

export_selection() {
    json_content=$(cat "$JSON_FILE")
    app_data=$(echo "$json_content" | jq -r '.[] | "\(.name) \(.is_enabled | if . == true then "ENABLED" else "DISABLED" end) \(.service_enabled)"')

    > "$ENV_DEPLOY_FILE" # Empty file

    echo "$app_data" | while IFS=' ' read -r name is_enabled service_enabled; do
        echo "$name=$is_enabled" >> "$ENV_DEPLOY_FILE"

        if [ "$service_enabled" != "null" ]; then
            if [ "$service_enabled" = "true" ]; then
                service_enabled="ENABLED"
            else
                service_enabled="DISABLED"
            fi
            echo "${name}_SERVICE=$service_enabled" >> "$ENV_DEPLOY_FILE"
        fi
    done
}

import_selection() {
    [ -f "$ENV_DEPLOY_FILE" ] || return

    jq_filter="map("
    while IFS='=' read -r name is_enabled; do
        app_enabled="false"
            [ "$is_enabled" = "ENABLED" ] && app_enabled="true"

        if [ "${name#*_SERVICE}" != "$name" ]; then
            jq_filter="$jq_filter if .name == \"${name%_SERVICE}\" then .service_enabled = $app_enabled else . end |"
        else
            jq_filter="$jq_filter if .name == \"$name\" then .is_enabled = $app_enabled else . end |"
        fi
    done < "$ENV_DEPLOY_FILE"

    jq_filter="${jq_filter%|}" # Remove trailing pipe
    jq --indent 4 "$jq_filter)" "$JSON_FILE" > "$JSON_FILE.tmp"
    mv "$JSON_FILE.tmp" "$JSON_FILE"
}

parse_cmd_arg() {
    if [ "$1" = "--default" ]; then
        updated_json_content=$(jq --indent 4 '. |= map(.is_enabled = true)' "$JSON_FILE")
        echo "$updated_json_content" > "$JSON_FILE"
        export_selection
        exit 0
    elif [ "$1" = "--export" ]; then
        export_selection
        exit 0
    elif [ "$1" = "--import" ]; then
        import_selection
        export_selection
        exit 0
    elif [ "$1" = "--backup" ]; then
        ENV_DEPLOY_FILE="$ENV_DEPLOY_FILE.backup"
        export_selection
        echo "\nBackup current app state successfully."
        exit 0
    elif [ "$1" = "--restore" ]; then
        tmp=$ENV_DEPLOY_FILE
        ENV_DEPLOY_FILE="$ENV_DEPLOY_FILE.backup"
        if [ -f "$ENV_DEPLOY_FILE" ]; then
            import_selection
            rm -f "$ENV_DEPLOY_FILE"
            ENV_DEPLOY_FILE=$tmp
            export_selection
            echo "\nSuccessfully re-applied app's enabled/disabled state from backup."
        else
            echo "\nNo backup found. Nothing to restore from."
        fi
        exit 0
    fi
}

# Main script
parse_cmd_arg "$@"

while true; do
    choose_application_type "$1"
done
