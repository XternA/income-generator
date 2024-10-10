#!/bin/sh

display_banner() {
    clear
    echo "Income Generator Proxy Manager"
    echo "${GREEN}----------------------------------------${NC}\n"
}

setup_proxy() {
    display_banner
    still_has_apps="$CONTAINER_ALIAS compose -p igm-proxy $LOADED_ENV_FILES $ALL_COMPOSE_FILES ps -a -q"

    if [ ! -z "$($still_has_apps -q)" ]; then
        echo "Proxy application still active."
        echo "\nRemove existing applications first before editing."
        printf "\nPress Enter to continue..."; read input
    else
        echo "After making changes, press '${BLUE}CTRL + X${NC}' and press '${BLUE}Y${NC}' to save changes."
        printf "\nPress Enter to continue..."; read input
        nano "$PROXY_FILE"
    fi
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

main_menu() {
    while true; do
        display_banner

        TOTAL_PROXIES=$([ -e "$PROXY_FILE" ] && awk 'NF {count++} END {print count}' "$PROXY_FILE" || echo 0)
        echo "Available Proxies: ${RED}${TOTAL_PROXIES}${NC}\n"

        options="(1-5)"
        echo "1. Setup Proxies"
        echo "2. Install Proxy Applications"
        echo "3. Remove Proxy Applications"
        echo "4. View Proxies"
        echo "5. Show Installed Applications"
        echo "0. Quit"
        echo
        read -p "Select an option $options: " choice

        case $choice in
            0) display_banner Proxy; echo "Quitting..."; sleep 0.62; clear; break ;;
            1) setup_proxy ;;
            2) sh "scripts/proxy/proxy-manager.sh" install ;;
            3) sh "scripts/proxy/proxy-manager.sh" remove ;;
            4) view_proxy ;;
            5) show_applications proxy ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac
    done
}

# Main script
if [ "$1" = "setup" ]; then
    setup_proxy
else
    main_menu
fi
