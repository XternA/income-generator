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

install_proxy_instance() {
    display_banner
    app_data=$(jq -r '.[] | select(.is_enabled == true) | "\(.name)"' "$JSON_FILE")

    echo "The following applications will be proxy installed.\n"

    printf "%-4s %-21s\n" "No." "Name"
    printf "%-4s %-21s\n" "---" "--------------------"
    printf "%s\n" "$app_data" | awk -v GREEN="$GREEN" -v NC="$NC" '
    BEGIN { counter = 1 }
    {
        printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
        counter++
    }'

    for compose_file in $COMPOSE_FILES; do [ "$compose_file" != "-f" ] && cp "$compose_file" "$compose_file.bak"; done
    cp "$TUNNEL_FILE" "$TUNNEL_FILE.bak"

    echo "\nPulling latest image..."
    $CONTAINER_ALIAS compose $LOADED_ENV_FILES --profile ENABLED $COMPOSE_FILES -f $TUNNEL_FILE pull
    echo "\nUsing Proxy File: ${BLUE}${INPUT_FILE}${NC}"
    echo "Total Proxies: ${RED}$(wc -l < $INPUT_FILE)${NC}\n"

    install_count=1
    while IFS= read -r proxy; do
        if echo "$proxy" | grep -Eq '^(socks5|socks4|https|http)://'; then
            PROXY="$proxy"
        else
            PROXY="${DEFAULT_PROTOCOL}${proxy}"
        fi

        echo "${GREEN}[ ${YELLOW}Installing Proxy Set ${RED}${install_count} ${GREEN}]${NC}"
        echo "Proxy Address: ${RED}$(echo $PROXY | cut -d'@' -f2)${NC}"
        echo "PROXY=$PROXY" > "$ENV_PROXY_FILE"

        echo "$app_data" | while read -r name; do
            app_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            echo "  ${GREEN}->${NC} ${app_name}-${install_count}"

            for compose_file in $COMPOSE_FILES; do
                if [ "$compose_file" != "-f" ]; then
                    # Check if app_name exists with digit suffix (like appname-1, appname-2, etc.)
                    if grep -q "^\([[:space:]]*\)${app_name}-[0-9]*:" "$compose_file"; then
                        new_app_name=$(grep "^\([[:space:]]*\)${app_name}-[0-9]*:" "$compose_file" | sed -n 's/.*-\([0-9]\+\):.*/\1/p' | sort -n | tail -n 1)
                        new_app_name="${app_name}-$((new_app_name + 1))"

                        # Update service and container names
                        sed -i "s/^\([[:space:]]*\)${app_name}-[0-9]*:/\1${new_app_name}:/" "$compose_file"
                        sed -i "s/^\([[:space:]]*\)container_name:[[:space:]]*${app_name}-[0-9]*\b/\1container_name: ${new_app_name}/" "$compose_file"

                        # Replace existing network_mode or add it under the profiles section
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

                        # Add network_mode correctly under profiles if it doesn't already exist
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
        $CONTAINER_ALIAS compose $LOADED_ENV_FILES -f $TUNNEL_FILE up --force-recreate --build -d > /dev/null 2>&1
        $CONTAINER_ALIAS compose $LOADED_ENV_FILES --profile ENABLED $COMPOSE_FILES up --force-recreate --build -d > /dev/null 2>&1
        install_count=$((install_count + 1))
        echo
    done < "$INPUT_FILE"

    for compose_file in $COMPOSE_FILES; do [ "$compose_file" != "-f" ] && mv "$compose_file.bak" "$compose_file"; done
    mv "$TUNNEL_FILE.bak" "$TUNNEL_FILE"

    echo "Proxy application install complete."
    printf "\nPress Enter to continue..."; read input
}

remove_proxy_instance() {
    display_banner
    app_data=$(jq -r '.[] | select(.is_enabled == true) | "\(.name)"' "$JSON_FILE")

    echo "The following prxoy applications will be removed.\n"

    printf "%-4s %-21s\n" "No." "Name"
    printf "%-4s %-21s\n" "---" "--------------------"
    printf "%s\n" "$app_data" | awk -v GREEN="$GREEN" -v NC="$NC" '
    BEGIN { counter = 1 }
    {
        printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
        counter++
    }'

    proxy_count="$(wc -l < $INPUT_FILE)"
    echo "\nTotal Proxies: ${RED}${proxy_count}${NC}\n"

    install_count=1
    while test "$install_count" -le "$proxy_count"; do
        echo "${GREEN}[ ${YELLOW}Removing Proxy Set ${RED}${install_count} ${GREEN}]${NC}"

        echo "$app_data" | while read -r name; do
            app_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            app_name="${app_name}-${install_count}"
            echo "  ${GREEN}->${NC} $app_name"
            $CONTAINER_ALIAS rm -f "$app_name" > /dev/null 2>&1
        done

        $CONTAINER_ALIAS rm -f tun2socks-${install_count} > /dev/null 2>&1
        install_count=$((install_count + 1))
        echo
    done < "$INPUT_FILE"

    echo "Proxy application uninstall complete."
    printf "\nPress Enter to continue..."; read input
}

# Main script
display_banner

# Detect input file with an exact name match in the root directory
INPUT_FILE=$(ls "$ROOT_DIR"/*.txt | grep -xE "$ROOT_DIR/(socks5.txt|socks4.txt|https.txt|http.txt|proxies.txt)" | head -n 1)

if [ -z "$INPUT_FILE" ]; then
    echo "No valid proxy file found! Expected socks5.txt, socks4.txt, https.txt, http.txt, or proxies.txt."
    exit 1
fi

# Determine the protocol based on the input file name
case "$(basename "$INPUT_FILE")" in
    socks5.txt)
        DEFAULT_PROTOCOL="socks5://"
        ;;
    socks4.txt)
        DEFAULT_PROTOCOL="socks4://"
        ;;
    https.txt)
        DEFAULT_PROTOCOL="https://"
        ;;
    http.txt)
        DEFAULT_PROTOCOL="http://"
        ;;
    *)
        DEFAULT_PROTOCOL=""  # No default protocol
        ;;
esac

> "$ENV_PROXY_FILE"

if [ -z "$1" ]; then
    install_proxy_instance
else
    [ "$1" = "remove" ] && remove_proxy_instance
fi