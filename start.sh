#!/bin/sh

sh scripts/init.sh

ARCH="$(sh scripts/arch.sh)"
STATS="$(sh scripts/limits.sh "$(sh scripts/set-limit.sh | awk '{print $NF}')")"
ENV_FILE="$(pwd)/.env"
ENV_DEPLOY_FILE="$(pwd)/.env.deploy"
COMPOSE="$(pwd)/compose"
ALL_COMPOSE_FILES="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml -f $COMPOSE/compose.local.yml -f $COMPOSE/compose.single.yml"

GREEN='\033[1;32m'
RED='\033[1;91m'
PINK='\033[1;35m'
BLUE='\033[1;36m'
NC='\033[0m'

display_banner() {
    clear
    echo "Income Generator Application Manager"
    echo "${GREEN}----------------------------------------${NC}"
    echo
}

stats() {
    printf "%s\n" "$ARCH"
    echo
    printf "%s\n" "$STATS"
    echo "${GREEN}----------------------------------------${NC}"
    echo
}

view_config() {
    KEY='\x1b[94m'     # Blue
    EQUALS='\x1b[91m'  # Red
    VALUE='\x1b[92m'   # Green
    RESET='\x1b[0m'    # Reset

    echo "${RED}---------[ START OF CONFIG ]---------\n"
    tail -n +14 "$ENV_FILE" | sed -e "s/^\([^=]*\)=\(.*\)$/${KEY}\1${EQUALS}=${VALUE}\2${RESET}/"
    echo "${RED}\n----------[ END OF CONFIG ]----------${NC}"
    printf "\nPress Enter to continue..."; read input
}

option_1() {
    while true; do
        display_banner
        options="(1-4)"

        [ "$1" = "quick_menu" ] && echo "How would you like to install?\n"
        echo "1. All applications including residential support"
        echo "2. Only applications with only VPS/Hosting support"
        echo "3. All applications with residential but exclude single install count"
        echo "4. Only applications allowing unlimited install count"
        [ "$1" = "quick_menu" ] && echo "0. Exit" || echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1|2|3|4)
                compose_files=""
                install_type="\n"
                case $option in
                    1)
                        install_type="Installing all application..."
                        compose_files=$ALL_COMPOSE_FILES
                        ;;
                    2)
                        install_type="Installing only applications supporting VPS/Hosting..."
                        compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml"
                        ;;
                    3)
                        install_type="Installing all applications, excluding single instances only..."
                        compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml -f $COMPOSE/compose.local.yml"
                        ;;
                    4)
                        install_type="Installing only applications with unlimited install count..."
                        compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml"
                        ;;
                    esac
                    display_banner

                    # Check if the separator line exists and get its line number
                    separator_line=$(grep -n "#--*$" $ENV_FILE | head -n 1)
                    if [ -n "$separator_line" ]; then
                        line_number=$(echo "$separator_line" | cut -d ":" -f 1)

                        # Check if there are lines after the separator
                        if ! tail -n "+$((line_number + 1))" $ENV_FILE | grep -v '^[[:space:]]*$' | grep -q "^"; then
                            echo "No configration for applications found. Make sure to complete the configuration setup."
                            echo "Running setup configuration now..."
                            sleep 0.6
                            sh scripts/config.sh
                            return
                        fi
                    fi

                    echo $install_type
                    echo
                    docker compose --env-file $ENV_FILE --env-file $ENV_DEPLOY_FILE --profile ENABLED $compose_files pull
                    docker container prune -f
                    docker compose --env-file $ENV_FILE --env-file $ENV_DEPLOY_FILE --profile ENABLED $compose_files up --force-recreate --build -d
                    ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                ;;
        esac
        printf "\nPress Enter to continue..."; read input
    done
}

option_2() {
    while true; do
        display_banner
        options="(1-5)"

        echo "1. Set up configuration"
        echo "2. View config file"
        echo "3. Edit config file"
        echo "4. Enable or disable applications"
        echo "5. Backup & restore config"
        echo "0. Back to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1)
                display_banner
                echo "Setting up application configuration..."
                sh scripts/config.sh
                printf "\nPress Enter to continue..."; read input
                ;;
            2)
                display_banner
                view_config
                ;;
            3)
                display_banner
                echo "Using nano editor. After making changes press '${BLUE}CTRL + X${NC}' and press '${BLUE}Y${NC}' to save changes."
                printf "\nPress Enter to continue..."; read input
                nano .env
                ;;
            4)
                sh scripts/app-selection.sh
                ;;
            5)
                sh scripts/backup-restore.sh
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

option_3() {
    display_banner
    echo "Starting applications...\n"
    docker compose --env-file $ENV_FILE --env-file $ENV_DEPLOY_FILE --profile ENABLED $ALL_COMPOSE_FILES start
    echo "\nAll installed applications started."
    printf "\nPress Enter to continue..."; read input
}

option_4() {
    display_banner
    echo "Stopping applications...\n"
    docker compose --env-file $ENV_FILE --env-file $ENV_DEPLOY_FILE --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES stop
    echo "\nAll running applications stopped."
    printf "\nPress Enter to continue..."; read input
}

option_5() {
    display_banner
    echo "Stopping and removing applications and volumes...\n"
    docker compose --env-file $ENV_FILE --env-file $ENV_DEPLOY_FILE --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES down -v
    docker container prune -f
    echo "\nAll installed applications and volumes removed."
    printf "\nPress Enter to continue..."; read input
}

option_6() {
    display_banner
    echo "Installed Containers:\n"
    docker compose --env-file $ENV_FILE --env-file $ENV_DEPLOY_FILE $ALL_COMPOSE_FILES ps -a
    printf "\nPress Enter to continue..."; read input
}

option_7() {
    while true; do
        display_banner
        options="(1-3)"

        echo "1. Docker Housekeeping"
        echo "2. Install Docker"
        echo "3. Uninstall Docker"
        echo "0. Back to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1)
                while true; do
                    display_banner
                    echo "[ Docker Housekeeping ]\n"
                    echo "Performing cleanup on orphaned applications and downloaded images."
                    echo "Orphaned applications currently running won't be cleaned up.\n"
                    read -p "Do you want to perform clean up? (Y/N): " yn

                    case $yn in
                        [Yy]*)
                            display_banner
                            docker system prune -a -f
                            echo "\nCleanup completed."
                            printf "\nPress Enter to continue..."; read input
                            break
                            ;;
                        [Nn]*)
                            break
                            ;;
                        *)
                            echo "\nPlease input yes (Y/y) or no (N/n)."
                            printf "\nPress Enter to continue..."; read input
                            ;;
                    esac
                done
                ;;
            2)
                display_banner
                echo "Installing Docker...\n"
                sh scripts/docker-install.sh
                sh scripts/emulation-layer.sh --add
                printf "\nPress Enter to continue..."; read input
                ;;
            3)
                display_banner
                echo "Uninstalling Docker...\n"
                sh scripts/docker-uninstall.sh
                sh scripts/emulation-layer.sh --remove
                printf "\nPress Enter to continue..."; read input
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

option_8() {
    while true; do
        display_banner
        options="(1-5)"

        echo "Pick a new resource limit utilization based on current hardware limits.\n"
        printf "%s\n" "$STATS"
        echo
        echo "1. BASE   -->   320MB RAM"
        echo "2. MIN    -->   12.5% Total RAM"
        echo "3. LOW    -->   18.75% Total RAM"
        echo "4. MID    -->   25% Total RAM"
        echo "5. MAX    -->   50% Total RAM"
        [ "$1" = "quick_menu" ] && echo "0. Exit" || echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1|2|3|4|5)
                limit_type=""
                case $option in
                    1) limit_type="base" ;;
                    2) limit_type="min" ;;
                    3) limit_type="low" ;;
                    4) limit_type="mid" ;;
                    5) limit_type="max" ;;
                esac
                echo
                sh scripts/set-limit.sh "$limit_type"
                STATS="$(sh scripts/limits.sh "$(sh scripts/set-limit.sh | awk '{print $NF}')")"
                echo "\nRedeploy applications for new limits to take effect."
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                ;;
        esac
        printf "\nPress Enter to continue..."; read input
    done
}

option_9() {
    while true; do
        display_banner

        options="(1-5)"

        echo "1. Backup & restore config"
        echo "2. Manage application state"
        echo "3. Reset resource limit"
        echo "4. Reset all back to default"
        echo "5. Check and get update"
        echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1)
                sh scripts/backup-restore.sh
                ;;
            2)
                while true; do
                    display_banner
                    options="(1-2)"

                    echo "Re-enable, restore saved application state.\n"
                    echo "1. Re-enable all applications"
                    echo "2. Restore from saved application state"
                    echo "0. Return to Main Menu"
                    echo
                    read -p "Select an option $options: " choice

                    case $choice in
                        1)
                            sh scripts/app-selection.sh --default
                            echo "\nAll applications have been re-enabled."
                            printf "\nPress Enter to continue..."; read input
                            ;;
                        2)
                            sh scripts/app-selection.sh --restore
                            printf "\nPress Enter to continue..."; read input
                            ;;
                        0)
                            break
                            ;;
                        *)
                            echo "\nInvalid option. Please select a valid option $options."
                            printf "\nPress Enter to continue..."; read input
                            ;;
                    esac
                done
                ;;
            3)
                echo
                sh scripts/set-limit.sh low
                STATS="$(sh scripts/limits.sh "$(sh scripts/set-limit.sh | awk '{print $NF}')")"
                printf "\nPress Enter to continue..."; read input
                ;;
            4)
                while true; do
                    display_banner
                    echo "${RED}WARNING!${NC}\n\nAbout to reset everything back to default."
                    echo "This will remove all configured credentials as well."
                    echo "Disabled apps will be re-enabled for deployment again.\n"

                    read -p "Do you want to backup credentials first? (Y/N): " yn
                    case $yn in
                        [Yy]*)
                            sh scripts/backup-restore.sh
                            sh scripts/app-selection.sh --backup
                            break
                            ;;
                        [Nn]*)
                            break
                            ;;
                        *)
                            echo "\nPlease input yes (Y/y) or no (N/n)."
                            ;;
                    esac
                    printf "\nPress Enter to continue..."; read input
                done

                display_banner
                rm -rf .env; sh scripts/init.sh > /dev/null 2>&1
                STATS="$(sh scripts/limits.sh "$(sh scripts/set-limit.sh | awk '{print $NF}')")"
                sh scripts/app-selection.sh --default

                echo "All settings have been reset. Please run ${PINK}Setup Configuration${NC} again."
                echo "Resource limits will need re-applying if previously set."
                echo "\nWhat settings can be restored?"
                echo "  - Application credentials if backed up."
                echo "  - State of applications that's been enabled/disabled for use."
                printf "\nPress Enter to continue..."; read input
                ;;
            5)
                sh scripts/check-tool-update.sh --update
                sh scripts/app-selection.sh --import
                unset NEW_UPDATE
                printf "\nPress Enter to continue..."; read input
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

# Main script
main_menu() {
    while true; do
        display_banner
        stats
        sh scripts/cleanup.sh
        [ -n "$NEW_UPDATE" ] && echo "$NEW_UPDATE\n"

        options="(1-9)"

        echo "1. Install & Run Applications"
        echo "2. Setup Configuration"
        echo "3. Start Applications"
        echo "4. Stop Applications"
        echo "5. Remove Applications"
        echo "6. Show Installed Applications"
        echo "7. Manage Docker"
        echo "8. Change Resource Limits"
        echo "9. Manage Tool"
        echo "0. Quit"
        echo
        read -p "Select an option $options: " choice

        case $choice in
            0) display_banner; echo "Quitting..."; sleep 0.62; clear; exit 0 ;;
            1) option_1 ;;
            2) option_2 ;;
            3) option_3 ;;
            4) option_4 ;;
            5) option_5 ;;
            6) option_6 ;;
            7) option_7 ;;
            8) option_8 ;;
            9) option_9 ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

case "$1" in
    --help|help)
        display_banner
        echo "Quick action menu of common operations.\n"
        echo "Usage: igm"
        echo "Usage: igm [command]"

        echo "\n[${BLUE}General${NC}]"
        echo "  igm                  Launch the Income Generator tool."
        echo "  igm help             Display this help usage guide."

        echo "\n[${BLUE}Manage${NC}]"
        echo "  igm start            Start all currently deployed applications."
        echo "  igm stop             Stop all currently deployed running applications."
        echo "  igm remove           Stop and remove all currently deployed applications."
        echo "  igm show             Show list of installed and running applications."
        echo "  igm deploy           Launch the install manager for deploying applications."

        echo "\n[${BLUE}Configuration${NC}]"
        echo "  igm app              Enable or disable applications for deployment."
        echo "  igm setup            Setup credentials for applications to be deployed."
        echo "  igm view             View all configured application credentials."
        echo "  igm edit             Edit configured credentials and config file directly."
        echo "  igm limit            Set the application resource limits."
        echo
        ;;
    start)
        option_3
        clear
        ;;
    stop)
        option_4
        clear
        ;;
    remove)
        option_5
        clear
        ;;
    show)
        option_6
        clear
        ;;
    deploy)
        option_1 quick_menu
        clear
        ;;
    app)
        sh scripts/app-selection.sh
        clear
        ;;
    setup)
        sh scripts/config.sh
        clear
        ;;
    view)
        display_banner
        view_config
        clear
        ;;
    edit)
        nano $ENV_FILE
        clear
        ;;
    limit)
        option_8 quick_menu
        clear
        ;;
    *)
        NEW_UPDATE="$(sh scripts/check-tool-update.sh)"
        main_menu
        ;;
esac
