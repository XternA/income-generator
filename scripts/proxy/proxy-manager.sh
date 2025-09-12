#!/bin/sh

. scripts/proxy/proxy-uuid-generator.sh
. scripts/util/app-import-reader.sh

PROXY_APP_NAME="tun2socks"
ENV_PROXY_FILE="$ROOT_DIR/.env.proxy"
TUNNEL_COMPOSE_FILE="$COMPOSE_DIR/compose.proxy.yml"
WATCHTOWER="sh $ROOT_DIR/scripts/runtime/watchtower.sh"

LOADED_ENV_FILES="
$SYSTEM_ENV_FILES
--env-file $ENV_DEPLOY_PROXY_FILE
--env-file $ENV_PROXY_FILE
"

COMPOSE_FILES="
-f $COMPOSE_DIR/compose.unlimited.yml
-f $COMPOSE_DIR/compose.hosting.yml
-f $COMPOSE_DIR/compose.local.yml
-f $COMPOSE_DIR/compose.single.yml
"

HOST="$(hostname)"

display_banner() {
    clear
    printf "Income Generator Proxy Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n\n"
}

retrieve_app_data() {
    APP_DATA=$(extract_app_data .alias .is_enabled .proxy_uuid)
}

set_host_suffix() {
    local suffix="${1:-}"

    if grep -q "^DEVICE_ID=" "$ENV_SYSTEM_FILE"; then
        $SED_INPLACE "s/^DEVICE_ID=.*/DEVICE_ID=${HOST}${suffix}/" "$ENV_SYSTEM_FILE"
    else
        echo "DEVICE_ID=${HOST}${suffix}" >> "$ENV_SYSTEM_FILE"
    fi
}

display_info() {
    display_banner
    type="$1"
    is_install="${2-true}"
    can_install="true"

    can_install_app=$(awk -v data="$APP_DATA" '
    BEGIN {
        n = split(data, lines, "\n")
        for (i = 1; i <= n; i++) {
            split(lines[i], f, " ")
            if (f[3] == "true") {
                print "true"
                exit
            }
        }
    }')

    if [ -z "$can_install_app" ]; then
        printf "No applications selected to install.\n"
        can_install="false"
    else
        printf "The following proxy applications will be $type.\n\n"
        printf "Total Proxies: ${RED}$ACTIVE_PROXIES${NC}\n\n"

        display_app_table "$APP_DATA" basic
    fi

    [ "$is_install" = "true" ] && printf "\nOption:\n  ${RED}a = select applications${NC}\n"

    if [ "$can_install" = "false" ]; then
        printf "\nSelect applications or press Enter to return: "
    else
        printf "\nDo you want to proceed? (Y/N): "
    fi
    read -r input
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

    printf "Proxy Address:  ${RED}$host_port${NC}\n"
    printf "Proxy Protocol: ${RED}$protocol_name${NC}\n"
}

update_app_uuid() {
    local app_name="$1"
    local index="$2"

    if [ "$proxy_uuid" != null ]; then
        proxy_file="$(get_proxy_file "$app_name")"
        uuid="$(awk "NR == $index { print; exit }" "$proxy_file")"

        id_name_type=$(echo "$proxy_uuid" | jq -r '.name_type')
        key_name="${app_name}_${id_name_type}"

        $SED_INPLACE "s/^${key_name}=[^ ]*/${key_name}=${uuid}/" "$ENV_FILE"
        export_active_uuid "$uuid" "$app_name"
    fi
}

install_proxy_instance() {
    while true; do
        display_info installed

        case "$input" in
            "")
                [ "$can_install" = "false" ] && exit 0
                printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                ;;
            a)
                $APP_SELECTION proxy proxy
                retrieve_app_data
                ;;
            [Yy])
                if [ "$can_install" = "true" ]; then
                    generate_uuid_files
                    break
                fi
                printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                ;;
            [Nn])
                if [ "$can_install" = "true" ]; then
                    clear
                    exit 0
                fi
                printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                ;;
            *)
                printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                ;;
        esac
    done

    > "$ENV_PROXY_FILE"

    for compose_file in $COMPOSE_FILES; do [ "$compose_file" != "-f" ] && cp "$compose_file" "$compose_file.bak"; done
    cp "$TUNNEL_COMPOSE_FILE" "$TUNNEL_COMPOSE_FILE.bak"
    cp "$ENV_FILE" "$ENV_FILE.bak"

    display_banner
    printf "Pulling latest image...\n\n"
    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $COMPOSE_FILES -f $TUNNEL_COMPOSE_FILE pull
    sleep 1.5

    display_banner
    printf "Installing proxy applications...\n\n"
    printf "Total Proxies: ${RED}$ACTIVE_PROXIES${NC}\n\n"

    install_count=1
    proxy_entry_pointer=1
    while IFS= read -r proxy_url; do
        if [ "$(echo "$proxy_url" | cut -c1)" = "#" ]; then
            proxy_entry_pointer=$((proxy_entry_pointer + 1)) # Skip UUID entry position matching proxy entry.
            continue # Skip entries not in use.
        fi

        printf "${GREEN}[ ${YELLOW}Installing Proxy Set ${RED}${install_count} ${GREEN}]${NC}\n"
        display_proxy_info "$proxy_url"
        echo "PROXY_URL=$proxy_url" > "$ENV_PROXY_FILE"

        echo "$APP_DATA" | while read -r name alias is_enabled proxy_uuid; do
            if [ "$alias" = null ]; then
                app_name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
            else
                app_name=$(printf '%s' "$alias" | tr '[:upper:]' '[:lower:]')
            fi
            printf " ${GREEN}->${NC} ${app_name}-${install_count}\n"

            for compose_file in $COMPOSE_FILES; do
                if [ "$compose_file" != "-f" ]; then
                    grep -q "$app_name" "$compose_file" || continue

                    if ! grep -q "${app_name}-[0-9]:" "$compose_file"; then
                        # Set project to proxy
                        $SED_INPLACE "s/project=standard/project=proxy/" "$compose_file"

                        # Replace DNS with proxy network
                        $SED_INPLACE "/^\([[:space:]]*\)- [0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}$/d" "$compose_file"
                        $SED_INPLACE "s/dns:/network_mode: \"container:${PROXY_APP_NAME}-${install_count}\"/" "$compose_file"
                        $SED_INPLACE "/hostname:/d" "$compose_file"

                        # Add depends on service
                        if ! grep -q "depends_on:" "$compose_file"; then
                            awk '/restart:/ {
                                print $0 "\n        depends_on:\n            - '"${PROXY_APP_NAME}-${install_count}"'"
                                next
                            } 1' "$compose_file" > tmp && mv tmp "$compose_file"
                        fi

                        # Remove defined ports
                        awk -v url="$proxy_url" '
                            BEGIN { skip_ports = 0; in_env = 0 }

                            # Remove ports section
                            /^[[:space:]]*ports:/ { skip_ports = 1; next }
                            skip_ports && /^[[:space:]]*-/ { next }
                            skip_ports && !/^[[:space:]]*-/ { skip_ports = 0 }
                            { print }
                        ' "$compose_file" > tmp && mv tmp "$compose_file"
                    fi

                    # Update container name
                    new_app_name="${app_name}-${install_count}"
                    $SED_INPLACE "s/^\([[:space:]]*\)${app_name}\(-[0-9][0-9]*\)\?:[[:space:]]*/\1${new_app_name}:/" "$compose_file"
                    $SED_INPLACE "s/container_name: ${app_name}\(-[0-9][0-9]*\)\?/container_name: ${new_app_name}/" "$compose_file"

                    # Update proxy network and depends on
                    $SED_INPLACE "s/\(${PROXY_APP_NAME}-\)[0-9]*/\1${install_count}/g" "$compose_file"

                    # Update volume dir
                    $SED_INPLACE "s#\(\$DATA_DIR/\)$app_name\(-[^:/]*\)\?:#\1$new_app_name:#" "$compose_file"
                fi
            done

            # Update app config file UUID
            update_app_uuid "$name" "$proxy_entry_pointer"
        done

        new_proxy_name="$PROXY_APP_NAME-${install_count}"
        if grep -q "${PROXY_APP_NAME}-[0-9]*:" "$TUNNEL_COMPOSE_FILE"; then
            $SED_INPLACE "s/${PROXY_APP_NAME}-[0-9]*:/${new_proxy_name}:/" "$TUNNEL_COMPOSE_FILE"
            $SED_INPLACE "s/container_name: ${PROXY_APP_NAME}-[0-9]*/container_name: ${new_proxy_name}/" "$TUNNEL_COMPOSE_FILE"
        else
            $SED_INPLACE "s/${PROXY_APP_NAME}:/${new_proxy_name}:/" "$TUNNEL_COMPOSE_FILE"
            $SED_INPLACE "s/container_name: ${PROXY_APP_NAME}/container_name: ${new_proxy_name}/" "$TUNNEL_COMPOSE_FILE"
        fi

        # Update and increment all ports
        awk '
            /^[[:space:]]*ports:/ { p=1; print; next }
            p && /^[[:space:]]*-[[:space:]]*[0-9]+:[0-9]+/ {
            split($2, a, ":")
            a[1]++
            print "            - " a[1] ":" a[2]
            next
            }
            { p=0; print }
        ' "$TUNNEL_COMPOSE_FILE" > tmp && mv tmp "$TUNNEL_COMPOSE_FILE"

        echo
        set_host_suffix "-${install_count}"
        $CONTAINER_ALIAS container prune -f > /dev/null 2>&1
        $CONTAINER_COMPOSE -p proxy-app-${install_count} $LOADED_ENV_FILES --profile ENABLED -f $TUNNEL_COMPOSE_FILE $COMPOSE_FILES up --force-recreate --build -d
        install_count=$((install_count + 1))
        proxy_entry_pointer=$((proxy_entry_pointer + 1))
        echo

        # Pause to give time for apps to load
        if [ "$ACTIVE_PROXIES" -gt 1 ] && [ "$install_count" -lt "$ACTIVE_PROXIES" ]; then
            sleep_time=$((10 + (install_count - 1) * 2))
            [ "$sleep_time" -gt 20 ] && sleep_time=20
            sleep "$sleep_time"
        fi
    done < "$PROXY_FILE"

    $WATCHTOWER deploy
    set_host_suffix

    for compose_file in $COMPOSE_FILES; do
        if [ "$compose_file" != "-f" ]; then
            mv "${compose_file}.bak" "$compose_file"
            rm -f "${compose_file}.bk"
        fi
    done
    mv "${TUNNEL_COMPOSE_FILE}.bak" "$TUNNEL_COMPOSE_FILE"
    mv "${ENV_FILE}.bak" "$ENV_FILE"
    rm -f "${TUNNEL_COMPOSE_FILE}.bk" "$ENV_PROXY_FILE"

    echo "Proxy application install complete."
    printf "\nPress Enter to continue..."; read -r input
}

remove_proxy_instance() {
    has_proxy_apps="$CONTAINER_ALIAS ps -a -q -f 'label=project=proxy' | head -n 1"
    if [ -z $(eval "$has_proxy_apps") ]; then
        display_banner
        echo "No installed proxy applications."
        printf "\nPress Enter to continue..."; read -r input
        return
    fi

    while true; do
        display_info removed false

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
    printf "\nTotal Proxies: ${RED}$ACTIVE_PROXIES${NC}\n\n"

    install_count=1
    while test "$install_count" -le "$ACTIVE_PROXIES"; do
        printf "${GREEN}[ ${YELLOW}Removing Proxy Set ${RED}${install_count} ${GREEN}]${NC}\n"

        echo "$APP_DATA" | while read -r name alias is_enabled proxy_uuid; do
            if [ "$alias" = null ]; then
                app_name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
            else
                app_name=$(printf '%s' "$alias" | tr '[:upper:]' '[:lower:]')
            fi
            app_name="${app_name}-${install_count}"
            printf " ${GREEN}->${NC} $app_name\n"
            $CONTAINER_ALIAS rm -f "$app_name" > /dev/null 2>&1
        done

        $CONTAINER_ALIAS rm -f ${PROXY_APP_NAME}-${install_count} > /dev/null 2>&1
        install_count=$((install_count + 1))
        echo
    done < "$PROXY_FILE"

    $WATCHTOWER restore
    $CONTAINER_ALIAS volume prune -a -f > /dev/null 2>&1
    rm -rf $PROXY_FOLDER_ACTIVE

    echo "Proxy application uninstall complete."
    printf "\nPress Enter to continue..."; read -r input
}

check_proxy_file() {
    if [ ! -e "$PROXY_FILE" ]; then
        echo "Proxy file doesn't exist.\nSetup proxy entries first."
        printf "\nPress Enter to continue..."; read -r input
        exit 0
    elif [ ! -s "$PROXY_FILE" ]; then
        echo "Proxy file is empty. Add entries first."
        printf "\nPress Enter to continue..."; read -r input
        exit 0
    fi

    # Ensure proxy entries are valid
    awk -v red="$RED" -v yellow="$YELLOW" -v reset="$NC" '
    /^[^#]/ {
        if ($0 !~ /^(socks5|socks4|http|ss|relay):\/\//) {
            printf "Found missing or invalid schema on line %s%d%s.\n", red, NR, reset
            print "Ensure proxy entries are correct."
            printf "\nSupported schema & format entry:\n"
            printf "\n  %ssocks5|socks4|http|shadowsocks|relay%s \n\n", yellow, reset
            printf "  %s->%s protocol://user:password@ip:port\n", red, reset
            printf "  %s->%s protocol://ip:port\n", red, reset
            exit 1
        }
    }
    ' "$PROXY_FILE"

    if [ $? -eq 1 ]; then
        printf "\nPress Enter to continue..."; read -r input
        exit 1
    fi
}

# Main script
display_banner
check_proxy_file
retrieve_app_data

case "$1" in
    install) install_proxy_instance ;;
    remove) remove_proxy_instance ;;
esac
