#!/bin/sh

GREEN='\033[0;92m'
RED='\033[0;91m'
BLUE='\033[1;96m'
NC='\033[0m'

JSON_FILE="$(pwd)/apps.json"
ENV_FILE="$(pwd)/.env.deploy"

display_banner() {
    clear
    echo "Income Generator Application Manager"
    echo "${GREEN}----------------------------------------${NC}"
    echo
}

display_table() {
    json_content=$(cat "$JSON_FILE")
    app_data=$(echo "$json_content" | jq -r '.[] | "\(.name) \(.is_enabled)"')

    # Table header
    printf "%-4s %-21s %-8s\n" "No." "App Name" "Status"
    printf "%-4s %-21s %-8s\n" "---" "--------------------" "--------"

    counter=1
    echo "$app_data" | while IFS=$'\n' read -r line; do
        name=$(echo "$line" | cut -d' ' -f1)
        is_enabled=$(echo "$line" | cut -d' ' -f2)

        if [ "$is_enabled" = "true" ]; then
            status="${GREEN}Enabled${NC}"
        else
            status="${RED}Disabled${NC}"
        fi

        # Content
        printf "%-4s %-21s %b\n" "$counter" "$name" "$status"
        counter=$((counter + 1))
    done
}

export_selection() {
    json_content=$(cat "$JSON_FILE")
    app_data=$(echo "$json_content" | jq -r '.[] | "\(.name) \(.is_enabled)"')

    if [ -f $ENV_FILE ]; then
        rm -f "$ENV_FILE"
    fi

    echo "$app_data" | while IFS=$'\n' read -r line; do
        name=$(echo "$line" | cut -d' ' -f1)
        is_enabled=$(echo "$line" | cut -d' ' -f2)

        echo "$name=$is_enabled" >> "$ENV_FILE"
    done
    exit 0
}

import_selection() {
    if [ -f $ENV_FILE ]; then
        while IFS='=' read -r name is_enabled; do
            updated_json_content=$(jq --indent 4 --arg name "$name" --arg is_enabled "$is_enabled" '. |= map(if .name == $name then .is_enabled = ($is_enabled | fromjson) else . end)' "$JSON_FILE")
            echo "$updated_json_content" > "$JSON_FILE"
        done < "$ENV_FILE"
    fi
    export_selection
    exit 0
}

parse_cmd_arg() {
    if [ "$1" = "--default" ]; then
        updated_json_content=$(jq --indent 4 '. |= map(.is_enabled = true)' "$JSON_FILE")
        echo "$updated_json_content" > "$JSON_FILE"
        export_selection
    elif [ "$1" = "--export" ]; then
        export_selection
    elif [ "$1" = "--import" ]; then
        import_selection
    fi
}

# Main script
parse_cmd_arg "$@"

while true; do
    display_banner
    echo "Disabled applications will not be deployed.\n"
    display_table

    echo "\nOptions:"
    echo "  ${GREEN}e${NC} = ${GREEN}enable all${NC}"
    echo "  ${RED}d${NC} = ${RED}disable all${NC}"
    echo "  ${BLUE}0${NC} = ${BLUE}exit${NC}"

    printf "\nSelect to ${GREEN}enable${NC} | ${RED}disable${NC} application (1-%s): " "$(echo "$app_data" | wc -l)"
    read -r choice

    case $choice in
        [1-9]*)
            # Enable or disable specific application
            if ! [ "$choice" -ge 1 ] || ! [ "$choice" -le "$(echo "$app_data" | wc -l)" ]; then
                echo "Invalid input! Please enter a number between 1 and $(echo "$app_data" | wc -l)."
                printf "\nPress Enter to continue..."; read input
            fi

            # Update entry
            chosen_app=$(echo "$app_data" | sed -n "${choice}p" | cut -d' ' -f1)
            updated_json_content=$(jq --indent 4 --arg chosen_app "$chosen_app" '. |= map(if .name == $chosen_app then .is_enabled |= not else . end)' "$JSON_FILE")
            echo "$updated_json_content" > "$JSON_FILE"
            ;;
        e)
            # Enable all
            updated_json_content=$(jq --indent 4 '. |= map(.is_enabled = true)' "$JSON_FILE")
            echo "$updated_json_content" > "$JSON_FILE"
            ;;
        d)
             # Disable all
            updated_json_content=$(jq --indent 4 '. |= map(.is_enabled = false)' "$JSON_FILE")
            echo "$updated_json_content" > "$JSON_FILE"
            ;;
        0)
            export_selection
            exit 0
            ;;
        *)
            echo "Invalid option! Please select a valid option."
            printf "\nPress Enter to continue..."; read input
            ;;
    esac
done
