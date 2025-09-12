#!/bin/sh

. scripts/util/app-import-reader.sh

display_banner() {
    clear
    printf "Income Generator Application Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n\n"
}

choose_application_type() {
    if [ "$1" = "service" ]; then
        field="service_enabled"
        app_type="Service"
        action="service"
        switch_type="applications"
        shortcut="a"
    else
        field="is_enabled"
        app_type="App"
        action="application"
        if [ "$1" = "proxy" ]; then
            switch_type=""
        else
            switch_type="services"
            shortcut="s"
        fi
    fi

    display_table_choice "$field" "$app_type" "$action" "$shortcut" "$switch_type"
}

display_table_choice() {
    local field_name="$1"
    local header="$2"
    local application="$3"
    local shortcut=$4
    local switch_type=$5

    while true; do
        display_banner
        printf "${RED}Disabled${NC} ${application}s will not be deployed.\n\n"

        app_data="$(extract_app_data_field $field_name)"
        display_app_table "$app_data"

        printf "\nOptions:\n"
        printf "  ${GREEN}e${NC} = ${GREEN}enable all${NC}\n"
        printf "  ${RED}d${NC} = ${RED}disable all${NC}\n"
        [ ! -z "$switch_type" ] && printf "  ${YELLOW}${shortcut}${NC} = ${YELLOW}select ${switch_type}${NC}\n"
        printf "  ${BLUE}0${NC} = ${BLUE}exit${NC}\n"

        printf "\nSelect to ${GREEN}enable${NC} | ${RED}disable${NC} $application (1-%s): " "$(echo "$app_data" | wc -l | xargs)"
        read -r choice

        case $choice in
            [1-9]*)
                # Enable or disable specific application
                if ! [ "$choice" -ge 1 ] || ! [ "$choice" -le "$(echo "$app_data" | wc -l)" ]; then
                    printf "\nInvalid input! Please enter a number between 1 and $(echo "$app_data" | wc -l).\n"
                    printf "\nPress Enter to continue..."; read -r input
                else
                    # Update entry
                    temp_file=$(mktemp)
                    chosen_app=$(echo "$app_data" | sed -n "${choice}p" | cut -d' ' -f1)
                    jq --indent 4 --arg chosen_app "$chosen_app" --arg field_name "$field_name" '. |= map(if .name == $chosen_app then .[$field_name] |= not else . end)' "$JSON_FILE" > "$temp_file"
                    mv "$temp_file" "$JSON_FILE"
                fi
                ;;
            e)
                # Enable all
                temp_file=$(mktemp)
                jq --indent 4 --arg field_name "$field_name" 'map(if has($field_name) then .[$field_name] = true else . end)' "$JSON_FILE" > "$temp_file"
                mv "$temp_file" "$JSON_FILE"
                ;;
            d)
                # Disable all
                temp_file=$(mktemp)
                jq --indent 4 --arg field_name "$field_name" 'map(if has($field_name) then .[$field_name] = false else . end)' "$JSON_FILE" > "$temp_file"
                mv "$temp_file" "$JSON_FILE"
                ;;
            a|s)
                if [ -z "$switch_type" ]; then
                    printf "\nInvalid option! Please select a valid option.\n"
                    printf "\nPress Enter to continue..."; read -r input
                else
                    if [ "$choice" = "s" ]; then
                        choose_application_type service
                    else
                        choose_application_type
                    fi
                    return
                fi
                ;;
            0)
                export_selection
                exit 0
                ;;
            *)
                printf "\nInvalid option! Please select a valid option.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

export_selection() {
    jq -r '.[] |
        "\(.name) " +
        (if .is_enabled then "ENABLED" else "DISABLED" end) + " " +
        (if .service_enabled != null then
            if .service_enabled then "ENABLED" else "DISABLED" end
        else
            "null"
        end)
    ' "$JSON_FILE" | {
        : > "$TARGET_DEPLOY_FILE"  # Empty file

        while IFS=' ' read -r name is_enabled service_enabled; do
            echo "$name=$is_enabled" >> "$TARGET_DEPLOY_FILE"

            [ "$service_enabled" != "null" ] && echo "${name}_SERVICE=$service_enabled" >> "$TARGET_DEPLOY_FILE"
        done
    }
}

import_selection() {
    [ -f "$TARGET_DEPLOY_FILE" ] || return

    jq_filter="."
    while IFS='=' read -r name is_enabled; do
        app_enabled="false"
        [ "$is_enabled" = "ENABLED" ] && app_enabled="true"

        if [ "${name#*_SERVICE}" != "$name" ]; then
            jq_filter="$jq_filter | (.[] | select(.name == \"${name%_SERVICE}\").service_enabled) = $app_enabled"
        else
            jq_filter="$jq_filter | (.[] | select(.name == \"$name\").is_enabled) = $app_enabled"
        fi
    done < "$TARGET_DEPLOY_FILE"

    jq --indent 4 "${jq_filter%|}" "$JSON_FILE" > "$JSON_FILE.tmp"
    mv "$JSON_FILE.tmp" "$JSON_FILE"
}

parse_cmd_arg() {
    if [ "$2" = "proxy" ]; then
        TARGET_DEPLOY_FILE="$ENV_DEPLOY_PROXY_FILE"
    else
        TARGET_DEPLOY_FILE="$ENV_DEPLOY_FILE"
    fi

    if [ "$1" = "--default" ]; then
        updated_json_content=$(jq --indent 4 '
            map(
                .is_enabled = true |
                if has("service_enabled") then .service_enabled = true else . end
            )
        ' "$JSON_FILE")
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
    elif [ "$1" = "--save" ]; then
        TARGET_DEPLOY_FILE="$TARGET_DEPLOY_FILE.save"
        export_selection
        exit 0
    elif [ "$1" = "--backup" ]; then
        TARGET_DEPLOY_FILE="$TARGET_DEPLOY_FILE.backup"
        export_selection
        echo "\nBackup current app state successfully."
        exit 0
    elif [ "$1" = "--restore" ]; then
        save_state=$([ "$2" = "redeploy" ] && echo true || echo false)

        tmp=$TARGET_DEPLOY_FILE
        if [ $save_state = "true" ]; then
            restore_type="save state"
            TARGET_DEPLOY_FILE="$TARGET_DEPLOY_FILE.save"
        else
            restore_type="backup"
            TARGET_DEPLOY_FILE="$TARGET_DEPLOY_FILE.backup"
        fi

        if [ -f "$TARGET_DEPLOY_FILE" ]; then
            import_selection
            [ $save_state = "false" ] && rm -f "$TARGET_DEPLOY_FILE"
            TARGET_DEPLOY_FILE=$tmp
            export_selection
            printf "\nSuccessfully re-applied app's enabled/disabled state from ${restore_type}.\n"
        else
            printf "\nNo ${restore_type} found. Nothing to restore from.\n"
        fi
        exit 0
    fi
}

# Main script
parse_cmd_arg "$@"

while true; do
    choose_application_type "$1"
done
