#!/bin/sh

. scripts/shared-component.sh
sh scripts/init.sh

. scripts/container/container-config.sh
. scripts/sub-menu/app-manager.sh
. scripts/arch-image-tag.sh

SYS_INFO=$($SYS_INFO)
STATS="$(sh scripts/limits.sh "$($SET_LIMIT | awk '{print $NF}')")"

display_banner() {
    clear
    echo "Income Generator Application Manager"
    echo -e "${GREEN}----------------------------------------${NC}\n"
}

stats() {
    printf "%s\n\n" "$SYS_INFO"
    printf "%s\n" "$STATS"
    echo -e "${GREEN}----------------------------------------${NC}\n"
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
        echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1)
                display_banner
                echo -e "Setting up application configuration...\n"
                $APP_CONFIG
                ;;
            2)
                display_banner
                $VIEW_CONFIG
                ;;
            3)
                display_banner
                echo -e "After making changes, press '${BLUE}CTRL + X${NC}' and press '${BLUE}Y${NC}' to save changes."
                printf "\nPress Enter to continue..."; read input
                nano .env
                ;;
            4)
                $APP_SELECTION
                ;;
            5)
                $BACKUP_RESTORE
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo -e "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

option_7() {
    while true; do
        display_banner
        options="(1-3)"

        echo "1. Docker Housekeeping"
        echo "2. Install Docker"
        echo "3. Uninstall Docker"
        echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1)
                while true; do
                    display_banner
                    echo -e "[ Docker Housekeeping ]\n"
                    echo "Performing cleanup on orphaned applications and downloaded images."
                    echo -e  "Orphaned applications currently running won't be cleaned up.\n"
                    read -p "Do you want to perform clean up? (Y/N): " yn

                    case $yn in
                        [Yy]*)
                            display_banner
                            echo -e "Removing orphaned applications, volumes and downloaded images...\n"
                            $CONTAINER_ALIAS system prune -a -f --volumes
                            echo -e "\nCleanup completed."
                            printf -e "\nPress Enter to continue..."; read input
                            break
                            ;;
                        [Nn]*)
                            break
                            ;;
                        *)
                            echo -e "\nPlease input yes (Y/y) or no (N/n)."
                            printf -e "\nPress Enter to continue..."; read input
                            ;;
                    esac
                done
                ;;
            2)
                display_banner
                echo -e "Installing Docker...\n"
                sh scripts/$CONTAINER_ALIAS-install.sh
                sh scripts/container/container-config.sh --register
                sh scripts/emulation-layer.sh --add
                printf "\nPress Enter to continue..."; read input
                ;;
            3)
                display_banner
                echo -e "Uninstalling Docker...\n"
                sh scripts/$CONTAINER_ALIAS-uninstall.sh
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

        echo -e "Pick a new resource limit utilization based on current hardware limits.\n"
        printf "%s\n" "$STATS"
        echo
        echo "1. BASE   -->   350MB RAM"
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
                $SET_LIMIT "$limit_type"
                STATS="$(sh scripts/limits.sh "$($SET_LIMIT | awk '{print $NF}')")"
                echo -e "\nRedeploy applications for new limits to take effect."
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo -e "\nInvalid option. Please select a valid option $options."
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
                $BACKUP_RESTORE
                ;;
            2)
                while true; do
                    display_banner
                    options="(1-2)"

                    echo -e "Re-enable, restore saved application state.\n"
                    echo "1. Re-enable all applications"
                    echo "2. Restore from saved application state"
                    echo "0. Return to Main Menu"
                    echo
                    read -p "Select an option $options: " choice

                    case $choice in
                        1)
                            $APP_SELECTION --default
                            echo -e "\nAll applications have been re-enabled."
                            printf "\nPress Enter to continue..."; read input
                            ;;
                        2)
                            $APP_SELECTION --restore
                            printf "\nPress Enter to continue..."; read input
                            ;;
                        0)
                            break
                            ;;
                        *)
                            echo -e "\nInvalid option. Please select a valid option $options."
                            printf "\nPress Enter to continue..."; read input
                            ;;
                    esac
                done
                ;;
            3)
                echo
                $SET_LIMIT low
                STATS="$(sh scripts/limits.sh "$($SET_LIMIT | awk '{print $NF}')")"
                printf "\nPress Enter to continue..."; read input
                ;;
            4)
                while true; do
                    display_banner
                    echo -e "${RED}WARNING!${NC}\n\nAbout to reset everything back to default."
                    echo "This will remove all configured credentials as well."
                    echo -e "Disabled apps will be re-enabled for deployment again.\n"

                    read -p "Do you want to backup credentials first? (Y/N): " yn
                    case $yn in
                        [Yy]*)
                            $BACKUP_RESTORE
                            $APP_SELECTION --backup
                            break
                            ;;
                        [Nn]*)
                            break
                            ;;
                        *)
                            echo -e "\nPlease input yes (Y/y) or no (N/n)."
                            ;;
                    esac
                    printf "\nPress Enter to continue..."; read input
                done

                display_banner
                rm -rf "$ENV_FILE" "$ENV_SYSTEM_FILE" "${ENV_DEPLOY_FILE}.save" "$ENV_DEPLOY_PROXY_FILE" "$ENV_IMAGE_TAG_FILE"
                sh scripts/init.sh > /dev/null 2>&1
                STATS="$(sh scripts/limits.sh "$($SET_LIMIT | awk '{print $NF}')")"
                $APP_SELECTION --default

                echo -e "All settings have been reset. Please run ${PINK}Setup Configuration${NC} again."
                echo "Resource limits will need re-applying if previously set."
                echo -e "\nWhat settings can be restored?"
                echo "  - Application credentials if backed up."
                echo "  - State of applications that's been enabled/disabled for use."
                printf "\nPress Enter to continue..."; read input
                ;;
            5)
                $UPDATE_CHECKER --update
                $APP_SELECTION --import
                unset NEW_UPDATE
                printf "\nPress Enter to continue..."; read input
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo -e "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

tool_reset() {
    while true; do
        display_banner
        read -p "Do you want to reset IGM system settings? (Y/N): " yn
        case $yn in
            [Yy]*)
                display_banner
                rm -rf .env.system
                echo "IGM system setting has been reset."
                printf "\nPress Enter to continue..."; read input
                break
                ;;
            ''|[Nn]*)
                break
                ;;
            *)
                echo -e "\nPlease input yes (Y/y) or no (N/n)."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

main_menu() {
    NEW_UPDATE=$($UPDATE_CHECKER)

    while true; do
        display_banner
        stats
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
            0) display_banner; echo "Quitting..."; sleep 0.62; clear; break ;;
            1) install_applications ;;
            2) option_2 ;;
            3) start_applications ;;
            4) stop_applications ;;
            5) remove_applications ;;
            6) show_applications ;;
            7) option_7 ;;
            8) option_8 ;;
            9) option_9 ;;
            *)
                echo -e "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

# Main script
trap '$POST_OPS; clear; exit 0' INT
$DECRYPT_CRED

case "$1" in
    -h|--help|help)
        display_banner
        echo -e "Quick action menu of common operations.\n"
        echo "Usage: igm"
        echo "Usage: igm [option]"
        echo "Usage: igm [option] [arg]"

        echo -e "\n[${BLUE}General${NC}]"
        echo "  igm                      Launch the Income Generator tool."
        echo "  igm help                 Display this help usage guide."

        echo -e "\n[${BLUE}Manage${NC}]"
        echo "  igm start  [name]        Start one or all currently deployed applications."
        echo "  igm stop   [name]        Stop one or all currently deployed running applications."
        echo "  igm remove [name]        Stop and remove one or all currently deployed applications."
        echo "  igm show   [app|proxy]   Show list of installed and running applications."
        echo "  igm deploy               Launch the install manager for deploying applications."
        echo "  igm redeploy             Redeploy the last installed application state."
        echo "  igm clean                Cleanup orphaned applications, volumes and downloaded images."

        echo -e "\n[${BLUE}Proxy${NC}]"
        echo "  igm proxy                Launch the proxy tool menu."
        echo "  igm proxy setup          Setup and define list of proxy entries."
        echo "  igm proxy app            Enable or disable proxy applications for deployment."
        echo "  igm proxy install        Install selected proxy applications."
        echo "  igm proxy remove         Remove all currently deployed proxy applications."
        echo "  igm proxy reset          Clear all proxy entries and remove proxy file."
        echo "  igm proxy id             Show active applications with multi-UUIDs and instructions."

        echo -e "\n[${BLUE}Configuration${NC}]"
        echo "  igm app|service          Enable or disable applications/services for deployment."
        echo "  igm setup                Setup credentials for applications to be deployed."
        echo "  igm view                 View all configured application credentials."
        echo "  igm edit                 Edit configured credentials and config file directly."
        echo "  igm limit                Set the application resource limits."
        echo
        ;;
    "")
        $APP_SELECTION --import
        main_menu
        ;;
    tool)
        if [ "$2" = "reset" ]; then
            tool_reset
            clear
        fi
        ;;
    proxy)
        case "$2" in
            ""|setup|app|install|remove|reset|id)
                set -- "$2"
                . scripts/proxy/proxy-menu.sh
                clear
                ;;
            *)
                echo "igm proxy: '$2' is not a valid command. See 'igm help'." ;;
        esac
        ;;
    start)
        if [ -n "$2" ]; then
            start_application "$2"
        else
            start_applications
            clear
        fi
        ;;
    stop)
        if [ -n "$2" ]; then
            stop_application "$2"
        else
            stop_applications
            clear
        fi
        ;;
    remove)
        if [ -n "$2" ]; then
            remove_application "$2"
        else
            remove_applications
            clear
        fi
        ;;
    show)
        show_applications "$2" "$3"
        clear
        ;;
    deploy)
        $APP_SELECTION --import
        install_applications quick_menu
        clear
        ;;
    redeploy)
        $APP_SELECTION --import
        reinstall_applications
        clear
        ;;
    clean)
        display_banner
        echo -e "Cleaning up orphaned applications, volumes and images...\n"
        $CONTAINER_ALIAS system prune -a -f --volumes
        ;;
    app|service)
        $APP_SELECTION --import
        $APP_SELECTION "$1"
        clear
        ;;
    setup)
        display_banner
        $APP_SELECTION --import
        $APP_CONFIG
        clear
        ;;
    view)
        display_banner
        $VIEW_CONFIG
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
        echo "igm: '$1' is not a valid command. See 'igm help'."
        ;;
esac
$POST_OPS
exit 0
