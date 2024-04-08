#!/bin/sh

sh "$(pwd)/scripts/jq-install.sh"

ENV_FILE="$(pwd)/.env"
JSON_FILE="$(pwd)/apps.json"

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'
NC='\033[0m'

display_banner() {
    clear
    printf $YELLOW
    echo "=========================================================="
    echo "#   Dotenv Configuration Script                          #"
    echo "=========================================================="
    echo "# Configure and update the configuration file setup      #"
    echo "# stored within a config file called .env.               #"
    echo "=========================================================="
    printf $NC
}

write_entry() {
    if [ "$is_update" = true ]; then
        awk -v entry="$entry_name" -v input="$input" -F "=" 'BEGIN { OFS="=" } $1 == entry { $2 = input } 1' "$ENV_FILE" > "$ENV_FILE.tmp"
        mv "$ENV_FILE.tmp" "$ENV_FILE"
    else
        echo "$entry_name=$input" >> "$ENV_FILE"
    fi
    echo 1 > /tmp/change_made
}

input_new_value() {
    printf "Enter a new value for $RED$entry_name$NC (or press Enter to skip): "; read -r input < /dev/tty
    if [ -n "$input" ]; then
        write_entry
    fi
}

generate_uuid() {
    if [ "$denoter" = "#" ]; then
        if [ $(uname) = 'Darwin' ]; then
            input=$(echo "sdk-node-")$(head -c 1024 /dev/urandom | md5)
        else
            input=$(echo -n "sdk-node-")$(head -c 1024 /dev/urandom | md5sum | tr -d ' -')
        fi
    elif [ "$denoter" = "*" ]; then
        if [ $(uname) = 'Darwin' ]; then
            input=$(uuidgen)
        else
            input=$(cat /proc/sys/kernel/random/uuid)
        fi
    fi
    write_entry
}

process_new_entry() {
    if [ "$entry" != "$entry_name" ]; then
        generate_uuid
        echo "A new UUID has been auto-generated for $RED$entry_name$NC: $YELLOW$input$NC\n"
        echo "Press Enter to continue..."; read -r input < /dev/tty
    else
        input_new_value
    fi
}

process_uuid_user_choice() {
    printf "Do you want to auto-generate a new UUID for $RED$entry_name$NC? (y/n): "; read -r input < /dev/tty
    if [ "$input" = "y" ]; then
        process_new_entry
    else
        printf "Do you want to define an existing UUID? (y/n): "; read -r input < /dev/tty
        if [ "$input" = "y" ]; then
            input_new_value
        fi
    fi
}

process_entries() {
    echo 0 > /tmp/change_made

    jq -c '.[]' "$JSON_FILE" | while read -r config_entry; do
        display_banner
        if [ $(echo "$config_entry" | jq -r '.is_enabled') = false ]; then
            continue
        fi

        app_name=$(echo "$config_entry" | jq -r '.name')
        url=$(echo "$config_entry" | jq -r '.url')
        description=$(echo "$config_entry" | jq -r '.description' | tr -d '\n')

        echo "\n[ $app_name ]"
        [ "$url" != null ] && echo "Go to $BLUE$url$NC to register account. (CTRL + Click)"
        [ "$description" != null ] && echo "$description"
        echo

        if [ -z "$(echo "$config_entry" | jq -r '.properties // empty')" ]; then
            printf "Press Enter to continue..."; read -r input < /dev/tty
            continue
        fi

        is_update=false
        properties=$(echo "$config_entry" | jq -r '.properties[]')

        if [ -n "$properties" ]; then
            # Check if properties is an array before looping through it
            if [ "$(echo "$config_entry" | jq -r '.properties | type')" = "array" ]; then
                for entry in $properties; do
                    entry_name=$(echo "$entry" | sed 's/^"//' | sed 's/"$//' | tr -d '*#') # Remove surrounding quotes and denoters
                    denoter=$(echo "$entry" | cut -c1)

                    if [ -n "$(grep "^$entry_name=" "$ENV_FILE")" ]; then
                        is_update=true
                    fi

                    if [ "$denoter" = "#" ] || [ "$denoter" = "*" ]; then
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

    change_made=$(cat /tmp/change_made)

    display_banner
    if [ "$change_made" -eq 1 ]; then
        echo "\nDone updating dotenv file '${RED}$ENV_FILE${NC}'."
    elif [ "$change_made" -eq 0 ] && [ ! -f "$ENV_FILE" ]; then
        echo "\nDotenv file '${RED}$ENV_FILE${NC}' was created."
    else
        echo "\nNo changes made to '${RED}$ENV_FILE${NC}'."
    fi
}

# Main script
if [ -f "$ENV_FILE" ]; then
    printf "\nDotenv file '${RED}$ENV_FILE${NC}' found. Configure it? (y/n): "; read -r input
    if [ "$input" = "y" ]; then
        process_entries
    else
        echo "No changes made to '${RED}$ENV_FILE${NC}'."
    fi
else
    echo "Dotenv file '${RED}$ENV_FILE${NC}' not found. Creating a new one...\n"
    sleep 1.2
    touch "$ENV_FILE"
    process_entries
fi
