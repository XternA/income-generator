#!/bin/sh

TEMP_FILE="$ENV_FILE.tmp"
BACKUP_FILE="$ENV_FILE.backup"

ENCRYPT_BACKUP="$ENCRYPTOR -es $BACKUP_FILE"
DECRYPT_BACKUP="$ENCRYPTOR -ds $BACKUP_FILE"

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
                    $VIEW_CONFIG
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
    cp -f "$ENV_FILE" "$BACKUP_FILE"

    printf "Backup completed. Content has been saved to ${RED}$BACKUP_FILE${NC}.\n"
}

restore_config() {
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "No backup file found. Nothing to restore."
        return
    fi
    mv -f $BACKUP_FILE $ENV_FILE

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
