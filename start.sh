#!/bin/sh

. scripts/banner.sh
. scripts/shared-component.sh
. scripts/core/system.sh
. scripts/core/resources.sh
. scripts/init.sh

. scripts/editor.sh
. scripts/arch-image-tag.sh
. scripts/arch-platform-runtime.sh
. scripts/sub-menu/app-manager.sh
. scripts/runtime/container-config.sh
. scripts/runtime/runtime-manager.sh

get_stats() {
    CORE_read_resource_limit
    current_limit="$CORE_RESOURCE_LIMIT"

    if [ "$current_limit" != "$__CACHED_LIMIT" ] || [ -z "$STATS" ]; then
        LIMIT_TYPE="$current_limit"
        . scripts/limits.sh
        __CACHED_LIMIT="$current_limit"
    fi
}

stats() {
    printf "%s\n\n" "$SYS_INFO"
    printf "$STATS\n"
    printf "${GREEN}------------------------------------------${NC}\n\n"
}

option_2() {
    options="(1-5)"
    
    while true; do
        display_banner

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
                printf "Setting up application configuration...\n\n"
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
    if [ "$1" = "quick_menu" ]; then
        return_option="0. Exit"
    else
        return_option="0. Return to Main Menu"
    fi

    options="(1-5)"
    while true; do
        display_banner    
        printf "Pick a new resource limit utilization based\non the current hardware limits.\n\n"
        printf "$STATS\n\n"
        echo "1. BASE   -->   350MB RAM"
        echo "2. MIN    -->   12.5% Total RAM"
        echo "3. LOW    -->   18.75% Total RAM"
        echo "4. MID    -->   25% Total RAM"
        echo "5. MAX    -->   50% Total RAM"
        echo "$return_option"
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
                get_stats
                printf "\nResource limit applied, live and active.\n"
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
    _urc=0
    case "$1" in
        --cli)
            $UPDATE_CHECKER --update; _urc=$?
            ;;
        --force)
            $UPDATE_CHECKER --force; _urc=$?
            ;;
        *)
            $UPDATE_CHECKER --update --tui; _urc=$?
            unset NEW_UPDATE
            ;;
    esac
    $APP_SELECTION --import
    printf "\nPress Enter to continue..."; read -r _
    return $_urc
}

manage_tool() {
    options="(1-6)"

    while true; do
        display_banner
        echo "1. Backup & restore config"
        echo "2. Manage application state"
        echo "3. Reset resource limit"
        echo "4. Reset all back to default"
        echo "5. Check and get update"
        echo "6. Change editor tool"
        echo "0. Return to Main Menu"
        printf "\nSelect an option $options: "; read -r option

        case $option in
            1)
                $BACKUP_RESTORE
                ;;
            2)
                options="(1-2)"

                while true; do
                    display_banner
                    printf "Re-enable, restore saved application state.\n\n"
                    echo "1. Re-enable all applications"
                    echo "2. Restore from saved application state"
                    echo "0. Return to Main Menu"
                    printf "\nSelect an option $options: "; read -r choice

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
                CORE_persist_limits
                get_stats
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
                get_stats
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

    options="(1-9)"

    while true; do
        display_banner --noline
        stats
        [ -n "$NEW_UPDATE" ] && printf "$NEW_UPDATE\n"

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
        printf "\nSelect an option $options: "; read -r choice

        case $choice in
            0) display_banner; echo "Quitting..."; sleep 0.62; clear_screen; break ;;
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

SYS_INFO="Hostname:         $CORE_HOSTNAME
Platform:         $CORE_OS_DISPLAY ($CORE_OS_ID)
Distro Ver:       $CORE_OS_CODENAME $CORE_OS_DISTRO_VERSION
Architecture:     $CORE_OS_ARCH ($CORE_DOCKER_DISPLAY_ARCH)"
__CACHED_LIMIT=""
get_stats

trap '$POST_OPS; clear_screen; exit 0' INT TERM HUP
$DECRYPT_CRED

case "$1" in
    -h|--help|help)
        display_banner
        . scripts/help.sh
        ;;
    -v|--version|version)
        . scripts/core/version.sh
        CORE_get_current_version
        printf "version: %s\n" "${CORE_CURRENT_VERSION:-unknown}"
        ;;
    "")
        $APP_SELECTION --import
        main_menu
        ;;
    tool)
        if [ "$2" = "reset" ]; then
            tool_reset
            clear_screen
        fi
        ;;
    proxy)
        set -- "$2"
        . scripts/proxy/proxy-menu.sh
        clear_screen
        ;;
    start)
        shift
        if [ "${1:-}" = "--proxy" ] && [ "$#" -eq 1 ]; then
            start_proxy_applications
        elif [ "$#" -gt 0 ]; then
            start_application_group "$@"
        else
            start_applications
            clear_screen
        fi
        ;;
    stop)
        shift
        if [ "${1:-}" = "--proxy" ] && [ "$#" -eq 1 ]; then
            stop_proxy_applications
        elif [ "$#" -gt 0 ]; then
            stop_application_group "$@"
        else
            stop_applications
            clear_screen
        fi
        ;;
    restart)
        shift
        restart_application_group "$@"
        ;;
    remove)
        shift
        if [ "${1:-}" = "--proxy" ] && [ "$#" -eq 1 ]; then
            remove_proxy_applications
        elif [ "$#" -gt 0 ]; then
            for app in "$@"; do
                remove_application "$app"
            done
        else
            remove_applications
            clear_screen
        fi
        ;;
    logs)
        show_application_log "$2"
        clear_screen
        ;;
    show)
        show_applications "$2" "$3"
        clear_screen
        ;;
    deploy)
        $APP_SELECTION --import
        install_applications quick_menu
        clear_screen
        ;;
    install)
        if [ -n "$2" ]; then
            $APP_SELECTION --import
            install_app_noninteractive "$2"
        else
            install_single_application
        fi
        clear_screen
        ;;
    uninstall)
        if [ -n "$2" ]; then
            $APP_SELECTION --import
            uninstall_app_noninteractive "$2"
        fi
        clear_screen
        ;;
    redeploy)
        $APP_SELECTION --import
        reinstall_applications
        clear_screen
        ;;
    clean)
        display_banner
        igm_cleanup "$2" --cli
        clear_screen
        ;;
    app|service)
        $APP_SELECTION --import
        $APP_SELECTION "$1"
        clear_screen
        ;;
    setup)
        display_banner
        $APP_SELECTION --import
        $APP_CONFIG
        clear_screen
        ;;
    view)
        display_banner
        $VIEW_CONFIG
        clear_screen
        ;;
    edit)
        run_editor $ENV_FILE
        clear_screen
        ;;
    limit)
        if [ -n "$2" ]; then
            $APP_SELECTION --import
            limit_noninteractive "$2"
        else
            option_8 quick_menu
        fi
        clear_screen
        ;;
    editor)
        display_banner
        set_editor
        clear_screen
        ;;
    update)
        case "$2" in
            --force) run_updater --force; _urc=$? ;;
            *) run_updater --cli; _urc=$? ;;
        esac
        clear_screen
        $POST_OPS
        exit $_urc
        ;;
    runtime)
        runtime_menu --cli
        clear_screen
        ;;
    ip)
        . scripts/ip/ip-score.sh
        clear_screen
        ;;
    wsl)
        case "${OS_IS_WSL}:$2" in
            true:mirror)
                sh scripts/runtime/wsl/wsl-networking.sh "$3"
                ;;
            true:*)
                display_banner
                . scripts/help/wsl-help.sh
                ;;
            *)
                echo "igm: '$1' is not a valid command. See 'igm help'."
                ;;
        esac
        ;;
    *)
        echo "igm: '$1' is not a valid command. See 'igm help'."
        ;;
esac
$POST_OPS
exit 0
