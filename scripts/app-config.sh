#!/bin/sh

FILE_CHANGED='.app_marker'
trap 'rm -f $FILE_CHANGED' INT

display_banner() {
    clear
    echo "${GREEN}==========================================================="
    echo "#     ${NC}Application Credential Setup Manager${GREEN}                #"
    echo "==========================================================="
    echo "#  ${NC}Manage, update and configure application credentials.${GREEN}  #"
    echo "#  ${NC}Credentials are stored locally in a ${RED}.env${NC} config file.${GREEN}  #"
    echo "===========================================================${NC}"
}

write_entry() {
    if [ "$is_update" = true ]; then
        awk -v entry="$entry_name" -v input="$input" -F "=" 'BEGIN { OFS="=" } $1 == entry { $2 = input } 1' "$ENV_FILE" > "$ENV_FILE.tmp"
        mv "$ENV_FILE.tmp" "$ENV_FILE"
    else
        if [ $is_new_app = true ]; then
            echo "" >> "$ENV_FILE"
            unset is_new_app
        fi
        echo "$entry_name=$input" >> "$ENV_FILE"
    fi
    : > $FILE_CHANGED
}

input_new_value() {
    printf "Enter a new value for $RED$entry_name$NC (or press Enter to skip): "; read -r input < /dev/tty
    [ -n "$input" ] && write_entry
}

generate_uuid() {
    if [ "$denoter" = "#" ]; then
        if [ "$(uname)" = 'Darwin' ]; then
            input=$(echo "sdk-node-")$(head -c 1024 /dev/urandom | md5)
        else
            input=$(echo -n "sdk-node-")$(head -c 1024 /dev/urandom | md5sum | tr -d ' -')
        fi
    elif [ "$denoter" = "*" ]; then
        if [ "$(uname)" = 'Darwin' ]; then
            input=$(uuidgen)
        else
            input=$(cat /proc/sys/kernel/random/uuid)
        fi
    elif [ "$denoter" = "&" ]; then
        input=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | dd bs=1 count=32 2>/dev/null)
    fi
    write_entry
}

process_new_entry() {
    if [ "$entry" != "$entry_name" ]; then
        generate_uuid
        echo "A new UUID has been auto-generated for $RED$entry_name$NC: $YELLOW$input$NC\n"
        [ "$registration" != null ] && echo "${YELLOW}$registration$input${NC}\n"
        echo "Press Enter to continue..."; read -r input < /dev/tty
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
        echo "\nConfiguring application ${RED}$entry_count${NC} of ${RED}$num_entries${NC}"

        app_name=$(echo "$config_entry" | jq -r '.name')
        url=$(echo "$config_entry" | jq -r '.url')
        description=$(echo "$config_entry" | jq -r '.description' | tr -d '\n')
        description_ext=$(echo "$config_entry" | jq -r '.description_ext' | tr -d '\n')
        registration=$(echo "$config_entry" | jq -r '.registration' | tr -d '\n')

        echo "\n[ ${GREEN}$app_name${NC} ]"
        [ "$url" != null ] && echo "Go to $BLUE$url$NC to register an account. (CTRL + Click)"
        [ "$description" != null ] && echo "Description: ${YELLOW}$description${NC}"
        [ "$description_ext" != null ] && echo "${YELLOW}$description_ext${NC}"
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
                    entry_name=$(echo "$entry" | sed 's/^"//' | sed 's/"$//' | tr -d "*#&") # Remove surrounding quotes and denoters
                    denoter=$(echo "$entry" | cut -c1)

                    [ -n "$(grep "^$entry_name=" "$ENV_FILE")" ] && is_update=true

                    if [ "$denoter" = "#" ] || [ "$denoter" = "*" ] || [ "$denoter" = "&" ]; then
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
        echo "\nDone configuring config file '${RED}$ENV_FILE${NC}'."
    else
        echo "\nNo changes made to '${RED}$ENV_FILE${NC}'."
    fi
    rm -f $FILE_CHANGED
}

# Main script
if [ -f "$ENV_FILE" ]; then
    echo "Credentials will be stored in '${RED}$ENV_FILE${NC}'"
    printf "\nStart the application setup process? (Y/N): "; read -r input
    if [ "$input" = "y" ]; then
        process_entries
    else
        echo "\nNo changes made to '${RED}$ENV_FILE${NC}'."
    fi
else
    echo "Dotenv file '${RED}$ENV_FILE${NC}' not found. Creating new one...\n"
    sleep 1.4
    touch "$ENV_FILE"
    process_entries
fi
printf "\nPress Enter to continue..."; read -r input < /dev/tty
