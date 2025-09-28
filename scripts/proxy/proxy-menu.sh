#!/bin/sh

. scripts/proxy/proxy-uuid-generator.sh
. scripts/util/app-import-reader.sh
. scripts/proxy/proxy-app-limiter.sh

HAS_PROXY_APPS="$CONTAINER_ALIAS ps -a -q -f 'label=project=proxy' | head -n 1"

display_banner() {
    clear
    printf "Income Generator Proxy Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n"
    [ ! "$1" = "--noline" ] && echo
}

setup_proxy() {
    display_banner
    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        printf "Proxy application still active.\nRemove existing applications first before editing.\n"
        printf "\nPress Enter to continue..."; read -r input
    else
        get_editor_description
        printf "\nPress Enter to continue..."; read -r input
        run_editor "$PROXY_FILE"
        [ -f "$PROXY_FILE" ] && [ "$(tail -c 1 "$PROXY_FILE")" != "" ] && echo "" >> "$PROXY_FILE"
    fi
}

select_proxy_app() {
    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        display_banner
        printf "Proxy application still active.\nRemove existing applications first.\n"
        printf "\nPress Enter to continue..."; read -r input
    else
        $APP_SELECTION proxy proxy
    fi
}

install_proxy_app() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    if [ "$ACTIVE_PROXIES" -le 0 ]; then
        printf "No proxy entries found.\nSetup proxy entries first.\n"
        printf "\nPress Enter to continue..."; read -r _
        return
    fi

    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        printf "Proxy application still active.\nRemove existing applications first.\n"
        printf "\nPress Enter to continue..."; read -r _
    else
        sh "scripts/proxy/proxy-manager.sh" install
    fi
}

remove_proxy_app() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    sh "scripts/proxy/proxy-manager.sh" remove
}

edit_proxy_file() {
    while true; do
        display_banner

        if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
            printf "Proxy application still active.\nRemove existing applications first.\n"
            printf "\nPress Enter to continue..."; read -r input
            return
        fi
        if [ ! -d "$PROXY_FOLDER" ]; then
            echo "No multi-UUIDs application entries found."
            printf "\nPress Enter to continue..."; read -r input
            return
        fi

        uuid_files="$(find "$PROXY_FOLDER" -maxdepth 1 -type f -printf '%f\n' | sed 's/\.[^.]*$//')"
        total_files="$(printf '%s\n' "$uuid_files" | wc -l)"
        options="(1-${total_files})"

        printf "Current applications with multiple UUIDs.\n\n"

        printf "%-4s %-21s\n" "No." "Name"
        printf "%-4s %-21s\n" "---" "--------------------"
        printf "%s\n" "$uuid_files" | awk -v GREEN="$GREEN" -v NC="$NC" '
        BEGIN { counter = 1 }
        {
            printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
            counter++
        }'
        printf "\nOption:\n  ${YELLOW}0${NC} = ${YELLOW}exit${NC}\n"

        printf "\nSelect an entry to edit $options: "; read -r input
        case "$input" in
            ''|*[!0-9]*)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                continue
                ;;
        esac

        [ "$input" -eq 0 ] && break

        if [ "$input" -ge 1 ] && [ "$input" -le "$total_files" ]; then
            display_banner
            app="$(set -- $uuid_files; eval echo \${$input})"

            get_editor_description
            printf "\nPress Enter to continue..."; read -r input
            run_editor "${PROXY_FOLDER}/${app}.uuid"
        else
            printf "\nInvalid option. Please select a valid option $options.\n"
            printf "\nPress Enter to continue..."; read -r input
        fi
    done
}

manage_uuids() {
    while true; do
        display_banner

        options="(1-3)"
        echo "1. View all generated UUID"
        echo "2. Edit generated UUIDs"
        echo "3. Clear generated UUIDs"
        echo "0. Return to Main Menu"
        echo

        printf "Select an option $options: "; read -r choice
        case $choice in
            0) break ;;
            1)
                display_banner
                if [ ! -d "$PROXY_FOLDER" ]; then
                    printf "No multi-UUIDs application entries found.\n\n"
                else
                    view_proxy_uuids all
                fi
                printf "Press Enter to continue..."; read -r input
                ;;
            2) edit_proxy_file ;;
            3)
                while true; do
                    display_banner

                    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
                        printf "Proxy application still active.\nRemove existing applications first.\n"
                        printf "\nPress Enter to continue..."; read -r input
                        break
                    fi
                    if [ ! -d "$PROXY_FOLDER" ]; then
                        echo "No multi-UUIDs application entries found."
                        printf "\nPress Enter to continue..."; read -r input
                        return
                    fi

                    printf "Do you want to clear all application generated multi-UUIDs?\n\n"
                    printf "You might want to backup if you wish to re-use the IDs later.\n\n"
                    printf "Do you really want to delete all entries? (Y/N): "; read -r yn

                    case $yn in
                        [Yy]*)
                            display_banner
                            rm -rf "$PROXY_FOLDER"
                            echo "All application generated UUIDs have been removed."
                            printf "\nPress Enter to continue..."; read -r input
                            break
                            ;;
                        [Nn]*)
                            break
                            ;;
                        *)
                            display_banner
                            echo "Please enter yes (Y/y) or no (N/n)."
                            printf "\nPress Enter to continue..."; read -r input
                            ;;
                    esac
                done
                ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

view_proxy() {
    display_banner
    if [ ! -e "$PROXY_FILE" ]; then
        echo "Proxy file doesn't exist.\nSetup proxy entries first."
        printf "\nPress Enter to continue..."; read -r input
    elif [ ! -s "$PROXY_FILE" ]; then
        echo "Proxy file is empty.\nAdd proxy entries first."
        printf "\nPress Enter to continue..."; read -r input
    else
        $VIEW_CONFIG "$PROXY_FILE" "PROXY"
    fi
}

reset_proxy() {
    display_banner
    if [ ! -e "$PROXY_FILE" ]; then
        echo "Proxy file doesn't exist."
        printf "\nPress Enter to continue..."; read -r input
    else
        if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
            printf "Proxy application still active.\nRemove existing applications first.\n"
            printf "\nPress Enter to continue..."; read -r input
        else
            while true; do
                display_banner
                printf "All proxy entries will be removed.\n\n"
                printf "Do you want to continue? (Y/N): "; read -r input

                case $input in
                    "")
                        break ;;
                    [yY])
                        display_banner
                        echo "All proxy entries removed."
                        rm -f "$PROXY_FILE"
                        printf "\nPress Enter to continue..."; read -r input
                        break
                        ;;
                    [nN])
                        break ;;
                    *)
                        printf "\nInvalid option. Please enter 'Y' or 'N'.\n"
                        printf "\nPress Enter to continue..."; read -r input
                        ;;
                esac
            done
        fi
    fi
}

view_uuids() {
    display_banner

    if [ -d "$PROXY_FOLDER_ACTIVE" ]; then
        printf "Multi-UUID applications with instruction need to be registered.\n"
        printf "Unregisted IDs will not count towards earnings.\n\n"
        printf "Deployed applications with in-use unqiue UUIDs are shown here.\n\n"

        view_proxy_uuids active
        printf "\nPress Enter to continue..."; read -r input
    else
        printf "Application with multi-UUIDs are auto generated during installtion.\n\n"
        printf "After installation, check here to view UUIDs and further instructions.\n"
        printf "\nPress Enter to continue..."; read -r input
    fi
}

run_proxy_app_limiter() {
    display_banner
    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        printf "Proxy application still active.\nRemove existing applications first.\n"
        printf "\nPress Enter to continue..."; read -r _
        return
    fi
    proxy_app_limiter
}

main_menu() {
    while true; do
        display_banner

        ACTIVE_PROXIES=$([ -e "$PROXY_FILE" ] && awk 'BEGIN {count=0} /^[^#]/ && NF {count++} END {print count}' "$PROXY_FILE" || echo 0)
        printf "Available Proxies: ${RED}${ACTIVE_PROXIES}${NC}\n\n"

        options="(1-9)"
        echo "1. Setup Proxies"
        echo "2. Select Applications"
        echo "3. Install Proxy Applications"
        echo "4. Remove Proxy Applications"
        echo "5. Show Installed Applications"
        echo "6. View Active UUIDs"
        echo "7. Manage UUIDs"
        echo "8. View Proxies"
        echo "9. Reset Proxies"
        echo "0. Quit"
        echo
        printf "Select an option $options: "; read -r choice

        case $choice in
            0) display_banner Proxy; echo "Quitting..."; sleep 0.62; clear; break ;;
            1) setup_proxy ;;
            2) select_proxy_app ;;
            3) install_proxy_app ;;
            4) remove_proxy_app ;;
            5) show_applications proxy ;;
            6) view_uuids ;;
            7) manage_uuids ;;
            8) view_proxy ;;
            9) reset_proxy ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

# Main script
if [ ! -f "$ENV_DEPLOY_PROXY_FILE" ]; then
    $APP_SELECTION --default proxy
else
    $APP_SELECTION --import proxy
fi

case "$1" in
    "") main_menu ;;
    setup) setup_proxy ;;
    app) select_proxy_app ;;
    install) install_proxy_app ;;
    remove) remove_proxy_app ;;
    reset) reset_proxy ;;
    id) view_uuids ;;
    limit) run_proxy_app_limiter ;;
    *) echo "igm proxy: '$1' is not a valid command. See 'igm help'."; exit ;;
esac
