#!/bin/sh

[ -n "$__PROXY_PORT_MAPPING_CACHED" ] && return
__PROXY_PORT_MAPPING_CACHED=1

_TMP_FILE="${TUNNEL_COMPOSE_FILE}.tmp"

# Strips the ports section and EXTRA_COMMANDS from tunâsocks,
# restoring it to its clean base state.
strip_port_mapping() {
    awk '
        /^[[:space:]]*ports:/ { skip=1; next }
        skip && /^[[:space:]]*-/ { next }
        skip && !/^[[:space:]]*-/ { skip=0 }
        /^[[:space:]]*- EXTRA_COMMANDS=/ { next }
        { print }
    ' "$TUNNEL_COMPOSE_FILE" > "$_TMP_FILE" && mv "$_TMP_FILE" "$TUNNEL_COMPOSE_FILE"
}

# Syncs tun2socks port mappings and iptables routing rules for a specific
# proxy set. Only injects ports for apps that are both enabled and within
# their install limit for the given set.
sync_port_mapping() {
    install_count="$1"

    if [ -z "$port_mapping_data_set" ]; then
        app_data=$(jq -r '.[] | select(has("proxy_port")) | "\(.name) \(.proxy_port.host) \(.proxy_port.container)"' "$JSON_FILE")
        port_mapping_data_set=1
    fi

    awk -v install_count="$install_count" \
        -v port_data="$app_data" \
        -v limit_data="$limit_data" \
        -v deployfile="$ENV_DEPLOY_PROXY_FILE" \
        '
        BEGIN {
            while ((getline line < deployfile) > 0) deploy[line] = 1
            close(deployfile)

            gsub(/\n/, " ", limit_data)
            n = split(limit_data, lf, " ")
            for (j = 1; j <= n; j += 2) if (lf[j] != "") limits[lf[j]] = lf[j+1]

            m = split(port_data, pl, "\n")
            for (i = 1; i <= m; i++) {
                if (pl[i] == "") continue
                split(pl[i], f, " ")
                name = f[1]; base_host = f[2]; cport = f[3]
                if (!(name "=ENABLED" in deploy)) continue
                lval = limits[name]
                if (lval != "" && lval != "-" && install_count+0 > lval+0) continue
                host_port = base_host + install_count
                ports = ports "            - " host_port ":" cport "\n"
                cports = (cports == "") ? cport : cports "," cport
            }

            if (ports != "") {
                rule = "iptables -t mangle -A OUTPUT -p tcp"
                rule = rule (cports ~ /,/ ? " -m multiport --sports " : " --sport ") cports
                extra_cmd = "            - EXTRA_COMMANDS=" rule " -j MARK --set-mark 0x22b"
            }
        }
        /^[[:space:]]*ports:/ { skip=1; next }
        skip && /^[[:space:]]*-/ { next }
        skip && !/^[[:space:]]*-/ { skip=0 }
        /^[[:space:]]*- EXTRA_COMMANDS=/ { next }
        /^[[:space:]]*- MTU=/ { print; if (extra_cmd) print extra_cmd; next }
        ports && /^[[:space:]]*devices:/ { printf "        ports:\n%s", ports }
        { print }
        ' "$TUNNEL_COMPOSE_FILE" > "$_TMP_FILE" && mv "$_TMP_FILE" "$TUNNEL_COMPOSE_FILE"
}
