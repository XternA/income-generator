#!/bin/sh

TEMP_FILE="$ENV_FILE.tmp"
BACKUP_FILE="$ENV_FILE.backup"

display_banner() {
    clear
    echo "Backup & Restore Config Manager"
    echo "${GREEN}----------------------------------------${NC}"
    echo
}

backup_config() {
    if [ -f "$BACKUP_FILE" ]; then
        while true; do
            display_banner
            options="(1-2)"

            echo "Backup file ${RED}$BACKUP_FILE${NC} already exists.\n"
            echo "Choose an option:\n"
            echo "1. View current backup file configuration"
            echo "2. View current in-use configuration"
            echo "3. Replace old backup with the current configurations"
            echo "0. Exit"
            echo
            read -p "Select an option $options: " option

            case "$option" in
                1)
                    display_banner
                    echo "Content of current backup file ${RED}$BACKUP_FILE${NC}.\n"
                    echo "${YELLOW}---------[ START OF BACKUP ]---------\n${BLUE}"
                    cat "$BACKUP_FILE"
                    echo "${YELLOW}\n----------[ END OF BACKUP ]----------${NC}"
                    ;;
                2)
                    display_banner
                    echo "Content of current in-use configuration.\n"
                    echo "${YELLOW}---------[ START OF CONFIG ]---------\n${BLUE}"
                    tail -n +14 $ENV_FILE
                    echo "${YELLOW}\n----------[ END OF CONFIG ]----------${NC}"
                    ;;
                3)
                    display_banner
                    echo "Replacing old backup file with the current configurations."
                    break
                    ;;
                0)
                    display_banner
                    exit 0
                    ;;
                *)
                    echo
                    echo "Invalid option. Please select a valid option $options."
                    ;;
            esac
            printf "\nPress Enter to continue..."; read input
        done
    fi

    BACKUP_FLAG=0
    : > "$BACKUP_FILE" # Clear previous backup file or create new

    while IFS= read -r line; do
        # Check if end of system config
        if [ "$line" = "#------------------------------------------------------------------------" ]; then
            BACKUP_FLAG=1
            continue
        fi

        # Skip the frst line after system config
        if [ "$BACKUP_FLAG" -eq 1 ] && [ -z "$line" ]; then
            BACKUP_FLAG=2
            continue
        fi

        if [ "$BACKUP_FLAG" -eq 2 ]; then
            echo "$line" >> "$BACKUP_FILE"
        fi
    done < "$ENV_FILE"

    echo "Backup completed. Content has been saved to ${RED}$BACKUP_FILE${NC}."
}

restore_config() {
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "No backup file found. Nothing to restore."
        return
    fi

    # Get system config
    awk '
    /#------------------------------------------------------------------------/ {
        print
        print ""
        exit
    }
    {print}
    ' "$ENV_FILE" > "$TEMP_FILE"

    echo "$(cat $BACKUP_FILE)" >> "$TEMP_FILE"
    mv -f "$TEMP_FILE" "$ENV_FILE"
    rm -f "$BACKUP_FILE"
    echo "Restore completed. Content has been restored from ${RED}$BACKUP_FILE${NC}."
}

remove_backup() {
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "No backup file found. Nothing to remove."
        return
    fi
    rm -f $BACKUP_FILE
    echo "Successfully removed backup config ${RED}$BACKUP_FILE${NC}."
}

# Main script
while true; do
    display_banner
    options="(1-3)"

    echo "What would you like to do?\n"
    echo "1. Backup config file"
    echo "2. Restore config file"
    echo "3. Delete backup file"
    echo "0. Exit"
    echo
    read -p "Select an option $options: " option

    case "$option" in
        1)
            display_banner
            backup_config
            ;;
        2)
            display_banner
            restore_config
            ;;
        3)
            display_banner
            remove_backup
            ;;
        0)
            exit 0
            ;;
        *)
            echo "\nInvalid option. Please select a valid option $options."
            ;;
    esac
    printf "\nPress Enter to continue..."; read input
done
