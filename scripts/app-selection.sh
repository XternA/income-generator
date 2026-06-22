#!/bin/sh

. scripts/banner.sh
. scripts/util/app-import-reader.sh


choose_application_type() {
    if [ "$1" = "service" ]; then
        total_apps="$TOTAL_SERVICES"
        field="service_enabled"
        app_type="Service"
        action="service"
        switch_type="applications"
        shortcut="a"
    else
        total_apps="$TOTAL_APPS"
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

    display_table_choice "$total_apps" "$field" "$app_type" "$action" "$shortcut" "$switch_type"
}

display_table_choice() {
    local total_apps="$1"
    local field_name="$2"
    local header="$3"
    local application="$4"
    local shortcut="$5"
    local switch_type="$6"

    while true; do
        display_banner
        printf "${RED}Disabled${NC} ${application}s will not be deployed.\n\n"

        app_data="$(CORE_extract_app_data_field $field_name)"
        display_app_table "$app_data"

        printf "\nOptions:\n"
        printf "  ${GREEN}e${NC} = ${GREEN}enable all${NC}\n"
        printf "  ${RED}d${NC} = ${RED}disable all${NC}\n"
        [ ! -z "$switch_type" ] && printf "  ${YELLOW}${shortcut}${NC} = ${YELLOW}select ${switch_type}${NC}\n"
        printf "  ${BLUE}0${NC} = ${BLUE}exit${NC}\n"

        printf "\nSelect to ${GREEN}enable${NC} | ${RED}disable${NC} $application (1-%s): " "$total_apps"
        read -r choice

        case $choice in
            [1-9]*)
                # Enable or disable specific application
                choice=$(printf '%s' "$choice" | tr -cd '0-9')
                if ! [ "$choice" -ge 1 ] || ! [ "$choice" -le "$total_apps" ]; then
                    printf "\nInvalid input! Please enter a number between 1 and $total_apps.\n"
                    printf "\nPress Enter to continue..."; read -r _
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
                    printf "\nInvalid input! Please enter a number between 1 and $TOTAL_APPS.\n"
                    printf "\nPress Enter to continue..."; read -r _
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
                CORE_export_selection "$TARGET_DEPLOY_FILE"
                exit 0
                ;;
            *)
                printf "\nInvalid option! Please select a valid option.\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
        esac
    done
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
        CORE_export_selection "$TARGET_DEPLOY_FILE"
        exit 0
    elif [ "$1" = "--export" ]; then
        CORE_export_selection "$TARGET_DEPLOY_FILE"
        exit 0
    elif [ "$1" = "--import" ]; then
        CORE_import_selection "$TARGET_DEPLOY_FILE"
        CORE_export_selection "$TARGET_DEPLOY_FILE"
        exit 0
    elif [ "$1" = "--save" ]; then
        CORE_export_selection "$TARGET_DEPLOY_FILE.save"
        exit 0
    elif [ "$1" = "--backup" ]; then
        CORE_export_selection "$TARGET_DEPLOY_FILE.backup"
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
            CORE_import_selection "$TARGET_DEPLOY_FILE"
            [ $save_state = "false" ] && rm -f "$TARGET_DEPLOY_FILE"
            TARGET_DEPLOY_FILE=$tmp
            CORE_export_selection "$TARGET_DEPLOY_FILE"
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
