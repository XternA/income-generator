#!/bin/sh

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
        $APP_SELECTION --import proxy
        $APP_SELECTION proxy proxy
    fi
}

install_proxy_app() {
    if [ ! -z $(eval "$HAS_PROXY_APPS") ]; then
        display_banner
        echo "Proxy application still active."
        echo "\nRemove existing applications first."
        printf "\nPress Enter to continue..."; read input
    else
        sh "scripts/proxy/proxy-manager.sh" install
    fi
}

remove_proxy_app() {
    sh "scripts/proxy/proxy-manager.sh" remove
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

main_menu() {
    while true; do
        display_banner

        TOTAL_PROXIES=$([ -e "$PROXY_FILE" ] && awk 'NF {count++} END {print count}' "$PROXY_FILE" || echo 0)
        echo "Available Proxies: ${RED}${TOTAL_PROXIES}${NC}\n"

        options="(1-7)"
        echo "1. Setup Proxies"
        echo "2. Select Applications"
        echo "3. Install Proxy Applications"
        echo "4. Remove Proxy Applications"
        echo "5. Show Installed Applications"
        echo "6. View Proxies"
        echo "7. Reset Proxies"
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
            6) view_proxy ;;
            7) reset_proxy ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

# Main script
case "$1" in
    setup) setup_proxy ;;
    install) install_proxy_app ;;
    remove) remove_proxy_app ;;
    reset) reset_proxy ;;
    *) main_menu ;;
esac
