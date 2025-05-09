#!/bin/sh

. scripts/util/uuid-generator.sh

FILE_CHANGED='.app_marker'
trap 'rm -f $FILE_CHANGED' INT

display_banner() {
    clear
    printf "${GREEN}===========================================================\n"
    printf "#  ${NC}Application Credential Setup Manager${GREEN}                   #\n"
    printf "===========================================================\n"
    printf "#  ${NC}Manage, update and configure application credentials.${GREEN}  #\n"
    printf "#  ${NC}Credentials are stored locally in a ${RED}.env${NC} config file.${GREEN}  #\n"
    printf "===========================================================${NC}\n"
}

write_entry() {
    if [ "$is_update" = true ]; then
        awk -v entry="$entry_name" -v input="$input" -F "=" 'BEGIN { OFS="=" } $1 == entry { $2 = input } 1' "$ENV_FILE" > "$ENV_FILE.tmp"
        mv "$ENV_FILE.tmp" "$ENV_FILE"
    else
        if [ $is_new_app = true ]; then
            echo "" >> "$ENV_FILE"
            is_new_app=false
        fi
        echo "$entry_name=$input" >> "$ENV_FILE"
    fi
    : > $FILE_CHANGED
}

input_new_value() {
    printf "Enter a new value for $RED$entry_name$NC (or press Enter to skip): "; read -r input < /dev/tty
    [ -n "$input" ] && write_entry
}

process_new_entry() {
    if [ "$entry" != "$entry_name" ]; then
        input="$(generate_uuid $denoter)"
        write_entry
        printf "A new UUID has been auto-generated for $RED$entry_name$NC: $YELLOW$input$NC\n\n"
        [ "$registration" != null ] && printf "${YELLOW}$registration$input${NC}\n"
        printf "\nPress Enter to continue..."; read -r input < /dev/tty
    else
        input_new_value
    fi
}

process_uuid_user_choice() {
    printf "Do you want to auto-generate a new UUID for $RED$entry_name$NC? (Y/N): "; read -r input < /dev/tty
    if [ "$input" = "y" ]; then
        process_new_entry
    else
        printf "Do you want to define an existing UUID? (Y/N): "; read -r input < /dev/tty
        [ "$input" = "y" ] && input_new_value
    fi
}

process_entries() {
    num_entries=$(jq '. | length' "$JSON_FILE")

    jq -c '.[]' "$JSON_FILE" | while read -r config_entry; do
        entry_count=$((entry_count + 1))
        [ $(echo "$config_entry" | jq -r '.is_enabled') = false ] && continue

        display_banner
        printf "\nConfiguring application ${RED}$entry_count${NC} of ${RED}$num_entries${NC}\n"

        app_name=$(echo "$config_entry" | jq -r '.name')
        url=$(echo "$config_entry" | jq -r '.url')
        description=$(echo "$config_entry" | jq -r '.description' | tr -d '\n')
        description_ext=$(echo "$config_entry" | jq -r '.description_ext' | tr -d '\n')
        registration=$(echo "$config_entry" | jq -r '.registration' | tr -d '\n')

        printf "\n[ ${GREEN}$app_name${NC} ]\n"
        [ "$url" != null ] && printf "Go to $BLUE$url$NC to register an account. (CTRL + Click)\n"
        [ "$description" != null ] && printf "Description: ${YELLOW}$description${NC}\n"
        [ "$description_ext" != null ] && printf "${YELLOW}$description_ext${NC}\n"
        echo

        if [ -z "$(echo "$config_entry" | jq -r '.properties // empty')" ]; then
            printf "Press Enter to continue..."; read -r input < /dev/tty
            continue
        fi

        is_update=false
        is_new_app=true
        properties=$(echo "$config_entry" | jq -r '.properties[]')

        if [ -n "$properties" ]; then
            # Check if properties is an array before looping through it
            if [ "$(echo "$config_entry" | jq -r '.properties | type')" = "array" ]; then
                for entry in $properties; do
                    entry_name=$(echo "$entry" | sed 's/^"//' | sed 's/"$//' | tr -d "#") # Remove surrounding quotes and denoter
                    require_uuid=$(echo "${entry%${entry#?}}")

                    [ -n "$(grep "^$entry_name=" "$ENV_FILE")" ] && is_update=true

                    if [ "$require_uuid" = "#" ]; then
                        denoter=$(echo "$config_entry" | jq -r '.uuid_type' | tr -d '\n')
                        process_uuid_user_choice
                    else
                        input_new_value
                    fi
                done
            fi
        else
            printf "Press Enter to continue..."; read -r input < /dev/tty
        fi
    done

    display_banner
    if [ -e "$FILE_CHANGED" ]; then
        printf "\nDone configuring config file '${RED}$ENV_FILE${NC}'.\n"
    else
        printf "\nNo changes made to '${RED}$ENV_FILE${NC}'.\n"
    fi
    rm -f $FILE_CHANGED
}

# Main script
if [ -f "$ENV_FILE" ]; then
    printf "Credentials will be stored in '${RED}$ENV_FILE${NC}'\n"
    printf "\nStart the application setup process? (Y/N): "; read -r input
    if [ "$input" = "y" ]; then
        process_entries
    else
        printf "\nNo changes made to '${RED}$ENV_FILE${NC}'.\n"
    fi
else
    printf "Dotenv file '${RED}$ENV_FILE${NC}' not found. Creating new one...\n\n"
    sleep 1.4
    touch "$ENV_FILE"
    process_entries
fi
printf "\nPress Enter to continue..."; read -r input < /dev/tty
