#!/bin/sh

ENV_PROXY_FILE="$ROOT_DIR/.env.proxy"
TUNNEL_FILE="$COMPOSE_DIR/compose.proxy.yml"

LOADED_ENV_FILES="
--env-file $ENV_FILE
--env-file $ENV_SYSTEM_FILE
--env-file $ENV_DEPLOY_FILE
--env-file $ENV_PROXY_FILE
"

COMPOSE_FILES="
-f $COMPOSE_DIR/compose.unlimited.yml
-f $COMPOSE_DIR/compose.hosting.yml
-f $COMPOSE_DIR/compose.local.yml
-f $COMPOSE_DIR/compose.single.yml
"

display_banner() {
    clear
    echo "Income Generator Proxy Manager"
    echo "${GREEN}----------------------------------------${NC}\n"
}

display_info() {
    display_banner
    echo "The following proxy applications will be $1.\n"
    echo "Total Proxies: ${RED}$TOTAL_PROXIES${NC}\n"

    printf "%-4s %-21s\n" "No." "Name"
    printf "%-4s %-21s\n" "---" "--------------------"
    printf "%s\n" "$APP_DATA" | awk -v GREEN="$GREEN" -v NC="$NC" '
    BEGIN { counter = 1 }
    {
        printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
        counter++
    }'

    printf "\nDo you want to proceed? (Y/N): "; read input
}

display_proxy_info() {
    local proxy_url="$1"
    local protocol_name
    local protocol="${proxy_url%%://*}"
    local host_port="${proxy_url#*://}"
    host_port="${host_port#*@}"  # Remove credentials
    host_port="${host_port%%[/?]*}"  # Remove anything after port or ? (for Relay)

    case "$protocol" in
        http) protocol_name="HTTP" ;;
        socks5) protocol_name="Socks5" ;;
        socks4) protocol_name="Socks4" ;;
        ss) protocol_name="Shadowsocks" ;;
        relay) protocol_name="Relay" ;;
        *) protocol_name="Unknown" ;;
    esac

    echo "Proxy Address:  ${RED}$host_port${NC}"
    echo "Proxy Protocol: ${RED}$protocol_name${NC}"
}

install_proxy_instance() {
    while true; do
        display_info installed

        case "$input" in
            [Yy])
                break
                ;;
            [Nn])
                clear
                exit 0
                ;;
            *)
                printf "\nInvalid option.\n\nPress Enter to continue..."; read input
                ;;
        esac
    done

    > "$ENV_PROXY_FILE"

    for compose_file in $COMPOSE_FILES; do [ "$compose_file" != "-f" ] && cp "$compose_file" "$compose_file.bak"; done
    cp "$TUNNEL_FILE" "$TUNNEL_FILE.bak"

    display_banner
    echo "Pulling latest image...\n"
    $CONTAINER_ALIAS compose $LOADED_ENV_FILES --profile ENABLED $COMPOSE_FILES -f $TUNNEL_FILE pull
    echo "\nTotal Proxies: ${RED}$TOTAL_PROXIES${NC}\n"

    install_count=1
    while IFS= read -r proxy_url; do
        echo "${GREEN}[ ${YELLOW}Installing Proxy Set ${RED}${install_count} ${GREEN}]${NC}"
        display_proxy_info $proxy_url
        echo "PROXY_URL=$proxy_url" > "$ENV_PROXY_FILE"

        echo "$APP_DATA" | while read -r name; do
            app_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            echo " ${GREEN}->${NC} ${app_name}-${install_count}"

            for compose_file in $COMPOSE_FILES; do
                if [ "$compose_file" != "-f" ]; then
                    if grep -q "^\([[:space:]]*\)${app_name}-[0-9]*:" "$compose_file"; then
                        new_app_name=$(grep "^\([[:space:]]*\)${app_name}-[0-9]*:" "$compose_file" | sed -n 's/.*-\([0-9]\+\):.*/\1/p' | sort -n | tail -n 1)
                        new_app_name="${app_name}-$((new_app_name + 1))"

                        # Update existing service and container names
                        sed -i "s/^\([[:space:]]*\)${app_name}-[0-9]*:/\1${new_app_name}:/" "$compose_file"
                        sed -i "s/^\([[:space:]]*\)container_name:[[:space:]]*${app_name}-[0-9]*\b/\1container_name: ${new_app_name}/" "$compose_file"

                        # Update proxy network
                        if grep -q "^\([[:space:]]*\)network_mode:" "$compose_file"; then
                            sed -i "s/^\([[:space:]]*\)network_mode:.*$/\1network_mode: \"container:tun2socks-${install_count}\"/" "$compose_file"
                        else
                            sed -i "/^\([[:space:]]*\)profiles:/a\        network_mode: \"container:tun2socks-${install_count}\"" "$compose_file"
                        fi
                    else
                        new_app_name="${app_name}-${install_count}"

                        # Update service and container names
                        sed -i "s/^\([[:space:]]*\)${app_name}:/\1${new_app_name}:/" "$compose_file"
                        sed -i "s/^\([[:space:]]*\)container_name:[[:space:]]*${app_name}/\1container_name: ${new_app_name}/" "$compose_file"

                        # Replace DNS with proxy network
                        if ! grep -q "^\([[:space:]]*\)network_mode:" "$compose_file"; then
                            sed -i "/^\([[:space:]]*\)dns:/,/^\([[:space:]]*\)- 8.8.8.8$/c\        network_mode: \"container:tun2socks-${install_count}\"" "$compose_file"
                        fi
                    fi
                fi
            done
        done

        if grep -q "^\([[:space:]]*\)tun2socks-[0-9]*:" "$TUNNEL_FILE"; then
            new_name=$(grep "^\([[:space:]]*\)tun2socks-[0-9]*:" "$TUNNEL_FILE" | sed -n 's/.*-\([0-9]\+\):.*/\1/p' | sort -n | tail -n 1)
            new_name="tun2socks-$((new_name + 1))"
            sed -i "s/^\([[:space:]]*\)tun2socks-[0-9]*:/\1${new_name}:/" "$TUNNEL_FILE"
            sed -i "s/^\([[:space:]]*\)container_name:[[:space:]]*tun2socks-[0-9]*\b/\1container_name: ${new_name}/" "$TUNNEL_FILE"
        else
            new_name="tun2socks-${install_count}"
            sed -i "s/^\([[:space:]]*\)tun2socks:/\1${new_name}:/" "$TUNNEL_FILE"
            sed -i "s/^\([[:space:]]*\)container_name:[[:space:]]*tun2socks/\1container_name: ${new_name}/" "$TUNNEL_FILE"
        fi

        $CONTAINER_ALIAS container prune -f > /dev/null 2>&1
        $CONTAINER_ALIAS compose -p igm-proxy $LOADED_ENV_FILES -f $TUNNEL_FILE up --force-recreate --build -d > /dev/null 2>&1
        $CONTAINER_ALIAS compose -p igm-proxy $LOADED_ENV_FILES --profile ENABLED $COMPOSE_FILES up --force-recreate --build -d > /dev/null 2>&1
        install_count=$((install_count + 1))
        echo
    done < "$PROXY_FILE"

    for compose_file in $COMPOSE_FILES; do [ "$compose_file" != "-f" ] && mv "$compose_file.bak" "$compose_file"; done
    mv "$TUNNEL_FILE.bak" "$TUNNEL_FILE"
    rm -f $ENV_PROXY_FILE

    echo "Proxy application install complete."
    printf "\nPress Enter to continue..."; read input
}

remove_proxy_instance() {
    while true; do
        display_info removed

        case "$input" in
            [Yy])
                break
                ;;
            [Nn])
                clear
                exit 0
                ;;
            *)
                printf "\nInvalid option.\n\nPress Enter to continue..."; read input
                ;;
        esac
    done

    display_banner
    echo "Removing proxy applications..."
    echo "\nTotal Proxies: ${RED}$TOTAL_PROXIES${NC}\n"

    install_count=1
    while test "$install_count" -le "$TOTAL_PROXIES"; do
        echo "${GREEN}[ ${YELLOW}Removing Proxy Set ${RED}${install_count} ${GREEN}]${NC}"

        echo "$APP_DATA" | while read -r name; do
            app_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            app_name="${app_name}-${install_count}"
            echo " ${GREEN}->${NC} $app_name"
            $CONTAINER_ALIAS rm -f "$app_name" > /dev/null 2>&1
        done

        $CONTAINER_ALIAS rm -f tun2socks-${install_count} > /dev/null 2>&1
        install_count=$((install_count + 1))
        echo
    done < "$PROXY_FILE"

    echo "Proxy application uninstall complete."
    printf "\nPress Enter to continue..."; read input
}

check_proxy_file() {
    if [ ! -e "$PROXY_FILE" ]; then
        echo "Proxy file doesn't exist.\nSetup proxy entries first."
        printf "\nPress Enter to continue..."; read input
        return
    elif [ ! -s "$PROXY_FILE" ]; then
        echo "Proxy file is empty. Add entries first."
        printf "\nPress Enter to continue..."; read input
        return
    fi

    # Ensure proxy entries are valid
    awk -v red="$RED" -v yellow="$YELLOW" -v reset="$NC" '
    {
        if ($0 !~ /^(socks5|socks4|http|ss|relay):\/\//) {
            printf "Found missing or invalid schema on line %s%d%s.\n", red, NR, reset
            print "Ensure proxy entries are correct."
            printf "\nSupported schema: %ssocks5|socks4|http|shadowsocks|relay%s\n", yellow, reset
            exit 1
        }
    }
    ' "$PROXY_FILE"

    if [ $? -eq 1 ]; then
        printf "\nPress Enter to continue..."; read input
        exit 1
    fi
}

# Main script
display_banner
check_proxy_file

APP_DATA=$(jq -r '.[] | select(.is_enabled == true) | "\(.name)"' "$JSON_FILE")
TOTAL_PROXIES=$(awk 'BEGIN {count=0} NF {count++} END {print count}' "$PROXY_FILE")

if [ "$1" = "install" ]; then
    install_proxy_instance
elif [ "$1" = "remove" ]; then
    remove_proxy_instance
fi
