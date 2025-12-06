#!/bin/sh

. scripts/shared-component.sh
sh scripts/init.sh

. scripts/editor.sh
. scripts/runtime/container-config.sh
. scripts/sub-menu/app-manager.sh
. scripts/arch-image-tag.sh
. scripts/arch-platform-runtime.sh
. scripts/runtime/runtime-manager.sh

SYS_INFO=$($SYS_INFO)
STATS="$(sh scripts/limits.sh "$($SET_LIMIT | awk '{print $NF}')")"

display_banner() {
    clear
    printf "Income Generator Application Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n"
    [ ! "$1" = "--noline" ] && echo
}

stats() {
    printf "%s\n\n" "$SYS_INFO"
    printf "%s\n" "$STATS"
    printf "${GREEN}------------------------------------------${NC}\n\n"
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
        printf "Select an option $options: "; read -r option

        case $option in
            1)
                display_banner
                printf "Setting up application configuration...\n"
                $APP_CONFIG
                ;;
            2)
                display_banner
                $VIEW_CONFIG
                ;;
            3)
                display_banner
                get_editor_description
                printf "\nPress Enter to continue..."; read -r input
                run_editor $ENV_FILE
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
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

option_8() {
    options="(1-5)"

    while true; do
        display_banner    

        printf "Pick a new resource limit utilization based\non the current hardware limits.\n\n"
        printf "%s\n\n" "$STATS"
        echo "1. BASE   -->   350MB RAM"
        echo "2. MIN    -->   12.5% Total RAM"
        echo "3. LOW    -->   18.75% Total RAM"
        echo "4. MID    -->   25% Total RAM"
        echo "5. MAX    -->   50% Total RAM"
        [ "$1" = "quick_menu" ] && echo "0. Exit" || echo "0. Return to Main Menu"
        printf "\nSelect an option $options: "; read -r option

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
                printf "\nRedeploy applications for new limits to take effect.\n"
                ;;
            0)
                break ;; # Return to the main menu
            *)
                printf "\nInvalid option. Please select a valid option $options.\n" ;;
        esac
        printf "\nPress Enter to continue..."; read -r _
    done
}

run_updater() {
    display_banner
    case "$1" in
        --cli)
            $UPDATE_CHECKER --update
            ;;
        --force)
            $UPDATE_CHECKER --force
            ;;
        *)
            $UPDATE_CHECKER --update
            unset NEW_UPDATE
            ;;
    esac
    $APP_SELECTION --import
    printf "\nPress Enter to continue..."; read -r _
}

manage_tool() {
    while true; do
        display_banner

        options="(1-6)"
        echo "1. Backup & restore config"
        echo "2. Manage application state"
        echo "3. Reset resource limit"
        echo "4. Reset all back to default"
        echo "5. Check and get update"
        echo "6. Change editor tool"
        echo "0. Return to Main Menu"
        echo
        printf "Select an option $options: "; read -r option

        case $option in
            1)
                $BACKUP_RESTORE
                ;;
            2)
                while true; do
                    display_banner
                    options="(1-2)"

                    printf "Re-enable, restore saved application state.\n\n"
                    echo "1. Re-enable all applications"
                    echo "2. Restore from saved application state"
                    echo "0. Return to Main Menu"
                    echo
                    printf "Select an option $options: "; read -r choice

                    case $choice in
                        1)
                            $APP_SELECTION --default
                            printf "\nAll applications have been re-enabled.\n"
                            printf "\nPress Enter to continue..."; read -r input
                            ;;
                        2)
                            $APP_SELECTION --restore
                            printf "\nPress Enter to continue..."; read -r input
                            ;;
                        0)
                            break
                            ;;
                        *)
                            printf "\nInvalid option. Please select a valid option $options.\n"
                            printf "\nPress Enter to continue..."; read -r input
                            ;;
                    esac
                done
                ;;
            3)
                echo
                $SET_LIMIT low
                STATS="$(sh scripts/limits.sh "$($SET_LIMIT | awk '{print $NF}')")"
                printf "\nPress Enter to continue..."; read -r input
                ;;
            4)
                while true; do
                    display_banner
                    printf "${RED}WARNING!${NC}\n\nAbout to reset everything back to default.\n"
                    printf "This will remove all configured credentials as well.\n"
                    printf "Disabled apps will be re-enabled for deployment again.\n"

                    printf "\nDo you want to backup credentials first? (Y/N): "; read -r yn
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
                            printf "\nPlease input yes (Y/y) or no (N/n).\n"
                            ;;
                    esac
                    printf "\nPress Enter to continue..."; read -r input
                done

                display_banner
                rm -rf "$ENV_FILE" "$ENV_SYSTEM_FILE" "${ENV_DEPLOY_FILE}.save" "$ENV_DEPLOY_PROXY_FILE" "$ENV_IMAGE_TAG_FILE" "$ENV_PLATFORM_OVERRIDE_FILE"
                
                # Re-init some default setups
                sh scripts/init.sh > /dev/null 2>&1
                STATS="$(sh scripts/limits.sh "$($SET_LIMIT | awk '{print $NF}')")"
                $APP_SELECTION --default
                run_arch_image_tag
                run_platform_override

                printf "All settings have been reset. Please run ${PINK}Setup Configuration${NC} again.\n"
                printf "Resource limits will need to be re-applied if previously set.\n"
                printf "Settings for Income Generator Proxy are left alone.\n"
                printf "\nWhat settings can be restored?\n"
                printf "  - Application credentials if previously backed up.\n"
                printf "  - State of applications that's been ${GREEN}enabled${NC}/${RED}disabled${NC} for use.\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
            5)
                run_updater
                ;;
            6)
                display_banner
                set_editor
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

tool_reset() {
    while true; do
        display_banner
        printf "Do you want to reset IGM system settings? (Y/N): "; read -r yn
        case $yn in
            [Yy]*)
                display_banner
                rm -rf .env.system
                echo "IGM system setting has been reset."
                printf "\nPress Enter to continue..."; read -r input
                break
                ;;
            ''|[Nn]*)
                break
                ;;
            *)
                printf "\nPlease input yes (Y/y) or no (N/n).\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

main_menu() {
    NEW_UPDATE=$($UPDATE_CHECKER)

    while true; do
        display_banner --noline
        stats
        [ -n "$NEW_UPDATE" ] && printf "$NEW_UPDATE\n"

        options="(1-9)"

        echo "1. Install & Run Applications"
        echo "2. Setup Configuration"
        echo "3. Start Applications"
        echo "4. Stop Applications"
        echo "5. Remove Applications"
        echo "6. Show Installed Applications"
        echo "7. Manage Runtime"
        echo "8. Change Resource Limits"
        echo "9. Manage Tool"
        echo "0. Quit"
        echo
        printf "Select an option $options: "; read -r choice

        case $choice in
            0) display_banner; echo "Quitting..."; sleep 0.62; clear; break ;;
            1) install_applications ;;
            2) option_2 ;;
            3) start_applications ;;
            4) stop_applications ;;
            5) remove_applications ;;
            6) show_applications group ;;
            7) runtime_menu ;;
            8) option_8 ;;
            9) manage_tool ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
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
        . scripts/help.sh
        ;;
    -v|--version|version)
        ver=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
        printf "version: $ver\n"
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
        set -- "$2"
        . scripts/proxy/proxy-menu.sh
        clear
        ;;
    start)
        shift
        if [ "$#" -gt 0 ]; then
            for app in "$@"; do
                start_application "$app"
            done
        else
            start_applications
            clear
        fi
        ;;
    stop)
        shift
        if [ "$#" -gt 0 ]; then
            for app in "$@"; do
                stop_application "$app"
            done
        else
            stop_applications
            clear
        fi
        ;;
    restart)
        if [ -n "$2" ]; then
            restart_application "$2"
        fi
        ;;
    remove)
        shift
        if [ "$#" -gt 0 ]; then
            for app in "$@"; do
                remove_application "$app"
            done
        else
            remove_applications
            clear
        fi
        ;;
    logs)
        display_banner
        show_application_log "$2"
        clear
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
        igm_cleanup "$2" --cli
        clear
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
        run_editor $ENV_FILE
        clear
        ;;
    limit)
        option_8 quick_menu
        clear
        ;;
    editor)
        display_banner
        set_editor
        clear
        ;;
    update)
        case "$2" in
            --force) run_updater --force ;;
            *) run_updater --cli ;;
        esac
        clear
        ;;
    runtime)
        runtime_menu
        clear
        ;;
    *)
        echo "igm: '$1' is not a valid command. See 'igm help'."
        ;;
esac
$POST_OPS
exit 0
