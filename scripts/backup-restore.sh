#!/bin/sh

TEMP_FILE="$ENV_FILE.tmp"
BACKUP_FILE="$ENV_FILE.backup"

ENCRYPT_BACKUP="$ENCRYPTOR -es $BACKUP_FILE"
DECRYPT_BACKUP="$ENCRYPTOR -ds $BACKUP_FILE"

# TODO temporary to migrate old config over to new
if grep -q "^#------------------------------------------------------------------------$" "$ENV_FILE"; then
    IS_OLD_CONFIG=true
else
    IS_OLD_CONFIG=false
fi

display_banner() {
    clear
    printf "Backup & Restore Config Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n\n"
}

backup_config() {
    if [ -f "$BACKUP_FILE" ]; then
        while true; do
            display_banner
            options="(1-3)"

            printf "Backup file ${RED}$BACKUP_FILE${NC} already exists.\n\n"
            printf "Choose an option:\n\n"
            echo "1. View current backup file configuration"
            echo "2. View current in-use configuration"
            echo "3. Replace old backup with the current configurations"
            echo "0. Exit"

            printf "\nSelect an option $options: "; read -r option
            case "$option" in
                1)
                    display_banner
                    $VIEW_CONFIG $BACKUP_FILE "BACKUP"
                    ;;
                2)
                    display_banner
                    printf "Content of current in-use configuration.\n\n"

                    # TODO - Remove in future updates
                    if [ "$IS_OLD_CONFIG" = true ]; then
                        printf "${YELLOW}---------[ START OF CONFIG ]---------\n${BLUE}\n"
                        tail -n +14 $ENV_FILE
                        printf "${YELLOW}\n----------[ END OF CONFIG ]----------${NC}\n"

                        printf "\nPress Enter to continue..."; read -r input
                    else
                        $VIEW_CONFIG
                    fi
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
                    printf "\nPress Enter to continue..."; read -r input
                    ;;
            esac
        done
    fi

    BACKUP_FLAG=0
    : > "$BACKUP_FILE" # Clear previous backup file or create new

    if [ "$IS_OLD_CONFIG" = true ]; then
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
    else
        cp -f "$ENV_FILE" "$BACKUP_FILE"
    fi

    printf "Backup completed. Content has been saved to ${RED}$BACKUP_FILE${NC}.\n"
}

restore_config() {
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "No backup file found. Nothing to restore."
        return
    fi

    if [ "$IS_OLD_CONFIG" = true ]; then
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
    else
        mv -f $BACKUP_FILE $ENV_FILE
    fi
    printf "Restore completed. Content has been restored from ${RED}$BACKUP_FILE${NC}.\n"
}

remove_backup() {
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "No backup file found. Nothing to remove."
        return
    fi
    rm -f $BACKUP_FILE
    printf "Successfully removed backup config ${RED}$BACKUP_FILE${NC}.\n"
}

# Main script
trap '$ENCRYPT_BACKUP' INT
$DECRYPT_BACKUP
while true; do
    display_banner
    options="(1-3)"

    printf "What would you like to do?\n\n"
    echo "1. Backup config file"
    echo "2. Restore config file"
    echo "3. Delete backup file"
    echo "0. Exit"
    echo
    printf "Select an option $options: "; read -r option

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
            $ENCRYPT_BACKUP
            exit 0
            ;;
        *)
            printf "\nInvalid option. Please select a valid option $options.\n"
            ;;
    esac
    printf "\nPress Enter to continue..."; read -r input
done
