#!/bin/sh

if [ $(uname) = 'Linux' ]; then
    SED_INPLACE="sed -i"
elif [ $(uname) = 'Darwin' ]; then
    SED_INPLACE="sed -i .bk"
fi

ENV_PROXY_FILE="$ROOT_DIR/.env.proxy"
TUNNEL_FILE="$COMPOSE_DIR/compose.proxy.yml"
PROXY_APP_NAME="tun2socks"

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
    local type="$1"
    local is_install="${2-false}"

    echo "The following proxy applications will be $type.\n"
    echo "Total Proxies: ${RED}$TOTAL_PROXIES${NC}\n"

    printf "%-4s %-21s\n" "No." "Name"
    printf "%-4s %-21s\n" "---" "--------------------"
    printf "%s\n" "$APP_DATA" | awk -v GREEN="$GREEN" -v NC="$NC" '
    BEGIN { counter = 1 }
    {
        printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
        counter++
    }'

    [ "$is_install" = "true" ] && echo "\nOption:\n  ${RED}a = select applications${NC}"
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
        display_info installed true

        case "$input" in
            a)
                $APP_SELECTION
                ;;
            [Yy])
                break
                ;;
            [Nn])
                clear
                exit 0
                ;;
            *)
                printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                ;;
        esac
    done

    > "$ENV_PROXY_FILE"

    for compose_file in $COMPOSE_FILES; do [ "$compose_file" != "-f" ] && cp "$compose_file" "$compose_file.bak"; done
    cp "$TUNNEL_FILE" "$TUNNEL_FILE.bak"

    display_banner
    echo "Pulling latest image...\n"
    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $COMPOSE_FILES -f $TUNNEL_FILE pull
    echo "\nTotal Proxies: ${RED}$TOTAL_PROXIES${NC}\n"

    install_count=1
    while IFS= read -r proxy_url; do
        echo "${GREEN}[ ${YELLOW}Installing Proxy Set ${RED}${install_count} ${GREEN}]${NC}"
        display_proxy_info "$proxy_url"
        echo "PROXY_URL=$proxy_url" > "$ENV_PROXY_FILE"

        echo "$APP_DATA" | while read -r name alias; do
            if [ "$alias" = null ]; then
                app_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            else
                 app_name=$(echo "$alias" | tr '[:upper:]' '[:lower:]')
            fi
            echo " ${GREEN}->${NC} ${app_name}-${install_count}"

            for compose_file in $COMPOSE_FILES; do
                if [ "$compose_file" != "-f" ]; then
                    new_app_name="${app_name}-${install_count}"

                    # Update containers already containing digit
                    if grep -q "${app_name}-[0-9]:" "$compose_file"; then
                        $SED_INPLACE "s/${app_name}-[0-9]:/${new_app_name}:/" "$compose_file"
                        $SED_INPLACE "s/container_name: ${app_name}-[0-9]/container_name: ${new_app_name}/" "$compose_file"

                        # Update proxy network
                        $SED_INPLACE "s/${PROXY_APP_NAME}-[0-9]/${PROXY_APP_NAME}-${install_count}/" "$compose_file"
                    else
                        $SED_INPLACE "s/${app_name}:/${new_app_name}:/" "$compose_file"
                        $SED_INPLACE "s/container_name: ${app_name}/container_name: ${new_app_name}/" "$compose_file"
                        $SED_INPLACE "s/project=standard/project=proxy/" "$compose_file"

                        # Replace DNS with proxy network
                        $SED_INPLACE "/^\([[:space:]]*\)- [0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}$/d" "$compose_file"
                        $SED_INPLACE "s/dns:/network_mode: \"container:${PROXY_APP_NAME}-${install_count}\"/" "$compose_file"
                        $SED_INPLACE "/network_mode: bridge$/d" "$compose_file"
                    fi
                fi
            done
        done

        new_proxy_name="$PROXY_APP_NAME-${install_count}"
        if grep -q "${PROXY_APP_NAME}-[0-9]:" "$TUNNEL_FILE"; then
            $SED_INPLACE "s/${PROXY_APP_NAME}-[0-9]:/${new_proxy_name}:/" "$TUNNEL_FILE"
            $SED_INPLACE "s/container_name: ${PROXY_APP_NAME}-[0-9]/container_name: ${new_proxy_name}/" "$TUNNEL_FILE"
        else
            $SED_INPLACE "s/${PROXY_APP_NAME}:/${new_proxy_name}:/" "$TUNNEL_FILE"
            $SED_INPLACE "s/container_name: ${PROXY_APP_NAME}/container_name: ${new_proxy_name}/" "$TUNNEL_FILE"
        fi

        echo
        $CONTAINER_ALIAS container prune -f > /dev/null 2>&1
        $CONTAINER_COMPOSE -p tunnel-${install_count} $LOADED_ENV_FILES -f $TUNNEL_FILE up --force-recreate --build -d > /dev/null 2>&1
        sleep 1
        $CONTAINER_COMPOSE -p proxy-app-${install_count} $LOADED_ENV_FILES --profile ENABLED $COMPOSE_FILES up --force-recreate --build -d
        install_count=$((install_count + 1))
        echo
    done < "$PROXY_FILE"

    for compose_file in $COMPOSE_FILES; do
        if [ "$compose_file" != "-f" ]; then
            mv "${compose_file}.bak" "$compose_file"
            rm -f "${compose_file}.bk"
        fi
    done
    mv "${TUNNEL_FILE}.bak" "$TUNNEL_FILE"
    rm -f "$ENV_PROXY_FILE ${TUNNEL_FILE}.bk"

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
                printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                ;;
        esac
    done

    display_banner
    echo "Removing proxy applications..."
    echo "\nTotal Proxies: ${RED}$TOTAL_PROXIES${NC}\n"

    install_count=1
    while test "$install_count" -le "$TOTAL_PROXIES"; do
        echo "${GREEN}[ ${YELLOW}Removing Proxy Set ${RED}${install_count} ${GREEN}]${NC}"

        echo "$APP_DATA" | while read -r name alias; do
            if [ "$alias" = null ]; then
                app_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            else
                 app_name=$(echo "$alias" | tr '[:upper:]' '[:lower:]')
            fi
            echo " ${GREEN}->${NC} ${app_name}-${install_count}"
            $CONTAINER_ALIAS rm -f "$app_name" > /dev/null 2>&1
        done

        $CONTAINER_ALIAS rm -f ${PROXY_APP_NAME}-${install_count} > /dev/null 2>&1
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

APP_DATA=$(jq -r '.[] | select(.is_enabled == true) | "\(.name) \(.alias)"' "$JSON_FILE")
TOTAL_PROXIES=$(awk 'BEGIN {count=0} NF {count++} END {print count}' "$PROXY_FILE")

case "$1" in
    install) install_proxy_instance ;;
    remove) remove_proxy_instance ;;
esac
