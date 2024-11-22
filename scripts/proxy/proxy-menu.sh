#!/bin/sh

. "scripts/proxy/proxy-uuid-generator.sh"

HAS_PROXY_APPS="$CONTAINER_ALIAS ps -a -q -f 'label=project=proxy' | head -n 1"

display_banner() {
    clear
    echo "Income Generator Proxy Manager"
    echo "${GREEN}----------------------------------------${NC}\n"
}

setup_proxy() {
    display_banner
    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        echo "Proxy application still active."
        echo "\nRemove existing applications first before editing."
        printf "\nPress Enter to continue..."; read input
    else
        echo "After making changes, press '${BLUE}CTRL + X${NC}' and press '${BLUE}Y${NC}' to save changes."
        printf "\nPress Enter to continue..."; read input
        nano "$PROXY_FILE"
        [ -f "$PROXY_FILE" ] && [ "$(tail -c 1 "$PROXY_FILE")" != "" ] && echo "" >> "$PROXY_FILE"
    fi
}

select_proxy_app() {
    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        display_banner
        echo "Proxy application still active."
        echo "\nRemove existing applications first."
        printf "\nPress Enter to continue..."; read input
    else
        $APP_SELECTION proxy proxy
    fi
}

install_proxy_app() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        echo "Proxy application still active."
        echo "\nRemove existing applications first."
        printf "\nPress Enter to continue..."; read input
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
            echo "Proxy application still active."
            echo "\nRemove existing applications first."
            printf "\nPress Enter to continue..."; read input
            return
        fi
        if [ ! -d "$PROXY_FOLDER" ]; then
            echo "No multi-UUIDs application entries found."
            printf "\nPress Enter to continue..."; read input
            return
        fi

        uuid_files="$(ls -1v "$PROXY_FOLDER" | sed 's/\.[^.]*$//')"
        total_files="$(echo "$uuid_files" | wc -l)"
        options="(1-${total_files})"

        echo "Current applications with multiple UUIDs.\n"

        printf "%-4s %-21s\n" "No." "Name"
        printf "%-4s %-21s\n" "---" "--------------------"
        printf "%s\n" "$uuid_files" | awk -v GREEN="$GREEN" -v NC="$NC" '
        BEGIN { counter = 1 }
        {
            printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
            counter++
        }'
        echo "\nOption:\n  ${YELLOW}0${NC} = ${YELLOW}exit${NC}"

        printf "\nSelect an entry to edit $options: "
        read -r input

        case "$input" in
            ''|*[!0-9]*)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                continue
                ;;
        esac

        [ "$input" -eq 0 ] && break

        if [ "$input" -ge 1 ] && [ "$input" -le "$total_files" ]; then
            display_banner
            app="$(set -- $uuid_files; eval echo \${$input})"
            echo "After making changes, press '${BLUE}CTRL + X${NC}' and press '${BLUE}Y${NC}' to save changes."
            printf "\nPress Enter to continue..."; read input
            nano "${PROXY_FOLDER}/${app}.uuid"
        else
            echo "\nInvalid option. Please select a valid option $options."
            printf "\nPress Enter to continue..."; read input
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
        read -p "Select an option $options: " choice

        case $choice in
            0) break ;;
            1)
                display_banner
                if [ ! -d "$PROXY_FOLDER" ]; then
                    echo "No multi-UUIDs application entries found.\n"
                else
                    view_proxy_uuids all
                fi
                printf "Press Enter to continue..."; read input
                ;;
            2) edit_proxy_file ;;
            3)
                while true; do
                    display_banner

                    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
                        echo "Proxy application still active."
                        echo "\nRemove existing applications first."
                        printf "\nPress Enter to continue..."; read input
                        break
                    fi
                    if [ ! -d "$PROXY_FOLDER" ]; then
                        echo "No multi-UUIDs application entries found."
                        printf "\nPress Enter to continue..."; read input
                        return
                    fi

                    echo "Do you want to clear all application generated multi-UUIDs?\n"
                    echo "You might want to backup if you wish to re-use the IDs later.\n"
                    read -p "Do you really want to delete all entries? (Y/N): " yn

                    case $yn in
                        [Yy]*)
                            display_banner
                            rm -rf "$PROXY_FOLDER"
                            echo "All application generated UUIDs have been removed."
                            printf "\nPress Enter to continue..."; read input
                            break
                            ;;
                        [Nn]*)
                            break
                            ;;
                        *)
                            display_banner
                            echo "Please enter yes (Y/y) or no (N/n)."
                            printf "\nPress Enter to continue..."; read input
                            ;;
                    esac
                done
                ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

view_proxy() {
    display_banner
    if [ ! -e "$PROXY_FILE" ]; then
        echo "Proxy file doesn't exist.\nSetup proxy entries first."
        printf "\nPress Enter to continue..."; read input
    elif [ ! -s "$PROXY_FILE" ]; then
        echo "Proxy file is empty.\nAdd proxy entries first."
        printf "\nPress Enter to continue..."; read input
    else
        $VIEW_CONFIG "$PROXY_FILE" "PROXY"
    fi
}

reset_proxy() {
    display_banner
    if [ ! -e "$PROXY_FILE" ]; then
        echo "Proxy file doesn't exist."
        printf "\nPress Enter to continue..."; read input
    else
        if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
            echo "Proxy application still active."
            echo "\nRemove existing applications first."
            printf "\nPress Enter to continue..."; read input
        else
            while true; do
                display_banner
                echo "All proxy entries will be removed.\n"
                read -p "Do you want to continue? (Y/N): " input

                case $input in
                    "")
                        break ;;
                    [yY])
                        display_banner
                        echo "All proxy entries removed."
                        rm -f "$PROXY_FILE"
                        printf "\nPress Enter to continue..."; read input
                        break
                        ;;
                    [nN])
                        break ;;
                    *)
                        echo "\nInvalid option. Please enter 'Y' or 'N'."
                        printf "\nPress Enter to continue..."; read input
                        ;;
                esac
            done
        fi
    fi
}

view_uuids() {
    display_banner

    if [ -d "$PROXY_FOLDER" ]; then
        echo "Multi-UUID applications with instruction need to be registered."
        echo "Unregisted IDs will not count towards earnings.\n"

        echo "Deployed applications with in-use unqiue UUIDs are shown here.\n"

        view_proxy_uuids active
        printf "Press Enter to continue..."; read input
    else
        echo "Application with multi-UUIDs are auto generated during installtion.\n"
        echo "After installation, check here to view UUIDs and further instructions."
        printf "\nPress Enter to continue..."; read input
    fi
}

main_menu() {
    while true; do
        display_banner

        TOTAL_PROXIES=$([ -e "$PROXY_FILE" ] && awk 'NF {count++} END {print count}' "$PROXY_FILE" || echo 0)
        echo "Available Proxies: ${RED}${TOTAL_PROXIES}${NC}\n"

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
        read -p "Select an option $options: " choice

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
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
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
    setup) setup_proxy ;;
    app) select_proxy_app ;;
    install) install_proxy_app ;;
    remove) remove_proxy_app ;;
    reset) reset_proxy ;;
    id) view_uuids ;;
    *) main_menu ;;
esac
