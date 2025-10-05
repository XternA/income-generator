#!/bin/sh

. scripts/util/uuid-generator.sh
. scripts/util/app-import-reader.sh

FILE_CHANGED='.app_marker'
trap 'rm -f $FILE_CHANGED' INT

display_banner() {
    clear
    printf "Income Generator Credentials Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n"
}

write_entry() {
    if [ "$is_update" = true ]; then
        awk -v entry="$entry_name" -v input="$input" -F "=" 'BEGIN { OFS="=" } $1 == entry { $2 = input } 1' "$ENV_FILE" >"$ENV_FILE.tmp"
        mv "$ENV_FILE.tmp" "$ENV_FILE"
    else
        if [ ! -s "$ENV_FILE" ]; then
            echo "$entry_name=$input" >"$ENV_FILE"
        else
            [ "$is_new_app" = true ] && {
                echo "" >> "$ENV_FILE"
                is_new_app=false
            }
            echo "$entry_name=$input" >>"$ENV_FILE"
        fi
    fi
    : > "$FILE_CHANGED"
}

input_new_value() {
    printf "Enter a new value for $RED$entry_name$NC (or press Enter to skip): "; read -r input < /dev/tty
    [ -n "$input" ] && write_entry
}

process_new_entry() {
    if [ "$entry" != "$entry_name" ]; then
        input="$(generate_uuid $uuid_type)"
        write_entry
        printf "A new UUID has been auto-generated for $RED$entry_name$NC: $YELLOW$input$NC\n\n"
        [ -n "$registration" ] && printf "${YELLOW}$registration$input${NC}\n\n"
        printf "Press Enter to continue..."; read -r input </dev/tty
    else
        input_new_value
    fi
}

process_uuid_user_choice() {
    printf "Do you want to auto-generate a new UUID for $RED$entry_name$NC? (Y/N): "; read -r input < /dev/tty
    case "$input" in
        y|Y) process_new_entry ;;
        *)
            printf "Do you want to define an existing UUID? (Y/N): "; read -r input < /dev/tty
            case "$input" in
                y|Y) input_new_value ;;
            esac
    esac
}

process_entries() {
    app_data=$(extract_and_map_app_data_field .name .url .description .description_ext .registration .properties:array .uuid_type)
    total_enabled_apps=$(printf '%s\n' "$app_data" | awk 'NF{n++} END{print n+0}')

    printf '%s\n' "$app_data" | while IFS= read -r config_entry; do
        eval "$config_entry" || continue

        [ "$is_enabled" = "false" ] && continue
        entry_count=$((entry_count + 1))
        is_update=false
        is_new_app=true

        display_banner
        printf "\nTotal applications: ${RED}$TOTAL_APPS${NC}\n"
        printf "\nConfiguring application ${RED}$entry_count${NC} of ${RED}$total_enabled_apps${NC}\n"
        printf "\n[ ${GREEN}$name${NC} ]\n"
        [ -n "$url" ] && printf "Go to $BLUE$url$NC to register an account. (CTRL + Click)\n"
        [ -n "$description" ] && printf "Description: ${YELLOW}$description${NC}\n"
        [ -n "$description_ext" ] && printf "${YELLOW}$description_ext${NC}\n"
        echo

        if [ -n "$properties" ]; then
            for entry in $properties; do
                entry_name=$(echo "$entry" | sed 's/^"//' | sed 's/"$//' | tr -d "#") # Remove surrounding quotes and denoter
                require_uuid=$(echo "${entry%${entry#?}}")

                [ -n "$(grep "^$entry_name=" "$ENV_FILE")" ] && is_update=true
                [ "$require_uuid" = "#" ] && process_uuid_user_choice || input_new_value
            done
        else
            printf "Press Enter to continue..."; read -r _ < /dev/tty
        fi
    done

    display_banner
    if [ -e "$FILE_CHANGED" ]; then
        printf "\nDone configuring config file '${RED}$ENV_FILE${NC}'.\n"
    else
        printf "\nNo changes made to '${RED}$ENV_FILE${NC}'.\n"
    fi
    rm -f "$FILE_CHANGED"
}

# Main script
if [ -f "$ENV_FILE" ]; then
    printf "Credentials will be stored in '${RED}$ENV_FILE${NC}'\n"
    printf "\nStart the application setup process? (Y/N): "; read -r input

    case "$input" in
        y|Y) process_entries ;;
        *) printf "\nNo changes made to '${RED}$ENV_FILE${NC}'.\n" ;;
    esac
else
    printf "Dotenv file '${RED}$ENV_FILE${NC}' not found. Creating new one...\n\n"
    sleep 1.4
    touch "$ENV_FILE"
    process_entries
fi
printf "\nPress Enter to continue..."; read -r _ < /dev/tty
