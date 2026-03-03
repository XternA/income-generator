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

    printf '%s\n%s\n' "$limit_data" "$app_data" | awk \
        -v install_count="$install_count" \
        -v deployfile="$ENV_DEPLOY_PROXY_FILE" \
        -v composefile="$TUNNEL_COMPOSE_FILE" \
        -v tmpfile="$_TMP_FILE" \
        'BEGIN {
            while ((getline) > 0) {
                if (/=/) { eq_pos=index($0,"="); if (eq_pos>1) limits[substr($0,1,eq_pos-1)] = substr($0,eq_pos+1) }
                else if (NF == 3) { app_order[++app_count] = $1; base_port[$1] = $2; cont_port[$1] = $3 }
            }
            while ((getline line < deployfile) > 0) deploy[line] = 1
            close(deployfile)
            for (i = 1; i <= app_count; i++) {
                name = app_order[i]
                if (!(name "=ENABLED" in deploy)) continue
                limit_val = limits[name]
                if (limit_val != "" && limit_val != "-" && install_count > limit_val+0) continue
                host_port = base_port[name] + install_count
                ports = ports "            - " host_port ":" cont_port[name] "\n"
                port_csv = (port_csv == "") ? cont_port[name] : port_csv "," cont_port[name]
            }
            if (ports != "") {
                rule = "iptables -t mangle -A OUTPUT -p tcp"
                rule = rule (port_csv ~ /,/ ? " -m multiport --sports " : " --sport ") port_csv
                extra_cmd = "            - EXTRA_COMMANDS=" rule " -j MARK --set-mark 0x22b"
            }
            while ((getline line < composefile) > 0) {
                if (line ~ /^[[:space:]]*ports:/) { skip=1; continue }
                if (skip && line ~ /^[[:space:]]*-/) continue
                if (skip && line !~ /^[[:space:]]*-/) skip=0
                if (line ~ /^[[:space:]]*- EXTRA_COMMANDS=/) continue
                if (line ~ /^[[:space:]]*- MTU=/) {
                    print line > tmpfile
                    if (extra_cmd) print extra_cmd > tmpfile
                    continue
                }
                if (ports && line ~ /^[[:space:]]*devices:/) printf "        ports:\n%s", ports > tmpfile
                print line > tmpfile
            }
            close(composefile)
            close(tmpfile)
        }'
    mv "$_TMP_FILE" "$TUNNEL_COMPOSE_FILE"
}
