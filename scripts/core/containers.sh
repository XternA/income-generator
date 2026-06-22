#!/bin/sh

[ -n "$__CORE_CONTAINERS_CACHED" ] && return
__CORE_CONTAINERS_CACHED=1

. scripts/core/common.sh

CORE_has_containers() {
    _type="$1"
    _proxy_num="$2"
    if [ -n "$_proxy_num" ] && [ "$_proxy_num" != "group" ]; then
        $CONTAINER_ALIAS ps -a -q -f "label=com.docker.compose.project=${_type}-app-${_proxy_num}" 2>/dev/null
    else
        $CONTAINER_ALIAS ps -a -q -f "label=project=${_type}" 2>/dev/null
    fi
}

CORE_get_container_table() {
    $CONTAINER_ALIAS ps -a -f "$1" \
        --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}"
}


CORE_show_proxy_groups() {
    _raw=$($CONTAINER_ALIAS ps -a --filter "label=project=proxy" \
        --format '{{.Label "com.docker.compose.project"}}\t{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}' \
        2>/dev/null)
    [ -z "$_raw" ] && return 1
    printf '%s\n' "$_raw" | awk -F'\t' \
        -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v RED="$RED" -v NC="$NC" \
'
{
    proj = $1
    id = $2; nm = $3; img = $4; cre = $5; sta = $6; por = $7
    gsub(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/, "", por)
    gsub(/\[::\]:/, "", por)
    gsub(/->[0-9]+/, "", por)
    _np = split(por, _pp, ", "); por = ""; delete _ps
    for (_k = 1; _k <= _np; _k++)
        if (_pp[_k] != "" && !(_pp[_k] in _ps)) { _ps[_pp[_k]] = 1; por = por (por ? ", " : "") _pp[_k] }
    rows[proj] = rows[proj] id "\t" nm "\t" img "\t" cre "\t" sta "\t" por "\n"
    cnt[proj]++
    if (length(id)  > w[1]) w[1] = length(id)
    if (length(nm)  > w[2]) w[2] = length(nm)
    if (length(img) > w[3]) w[3] = length(img)
    if (length(cre) > w[4]) w[4] = length(cre)
    if (length(sta) > w[5]) w[5] = length(sta)
    if (!(proj in seen)) { seen[proj] = 1; order[++ng] = proj }
}
END {
    for (i = 1; i <= ng; i++)
        for (j = i+1; j <= ng; j++) {
            split(order[i], a, "-"); ni = a[length(a)]+0
            split(order[j], b, "-"); nj = b[length(b)]+0
            if (ni > nj) { t = order[i]; order[i] = order[j]; order[j] = t }
        }
    hdr[1]="CONTAINER ID"; hdr[2]="NAMES"; hdr[3]="IMAGE"
    hdr[4]="CREATED";      hdr[5]="STATUS"; hdr[6]="PORTS"
    for (c = 1; c <= 5; c++) if (length(hdr[c]) > w[c]) w[c] = length(hdr[c])
    fmt = "%-" w[1] "s   %-" w[2] "s   %-" w[3] "s   %-" w[4] "s   %-" w[5] "s   %s\n"
    for (g = 1; g <= ng; g++) {
        p = order[g]
        printf "\n" GREEN "[ " YELLOW "Proxy Applications " NC "| " RED g NC " " GREEN "]" NC " (%d containers)\n\n", cnt[p]
        printf fmt, hdr[1], hdr[2], hdr[3], hdr[4], hdr[5], hdr[6]
        n = split(rows[p], lines, "\n")
        for (l = 1; l <= n; l++) {
            if (lines[l] == "") continue
            split(lines[l], f, "\t")
            printf fmt, f[1], f[2], f[3], f[4], f[5], f[6]
        }
    }
}
'
}

CORE_show_all_containers() {
    _raw=$($CONTAINER_ALIAS ps -a --filter "label=project" \
        --format '{{.Label "project"}}\t{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}' \
        2>/dev/null)
    [ -z "$_raw" ] && return 1
    printf '%s\n' "$_raw" | awk -F'\t' \
        -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v NC="$NC" \
'
{
    typ = $1; id = $2; nm = $3; img = $4; cre = $5; sta = $6; por = $7
    gsub(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/, "", por)
    gsub(/\[::\]:/, "", por)
    gsub(/->[0-9]+/, "", por)
    _np = split(por, _pp, ", "); por = ""; delete _ps
    for (_k = 1; _k <= _np; _k++)
        if (_pp[_k] != "" && !(_pp[_k] in _ps)) { _ps[_pp[_k]] = 1; por = por (por ? ", " : "") _pp[_k] }
    rows[typ] = rows[typ] id "\t" nm "\t" img "\t" cre "\t" sta "\t" por "\n"
    cnt[typ]++
    if (length(id)  > w[typ,1]) w[typ,1] = length(id)
    if (length(nm)  > w[typ,2]) w[typ,2] = length(nm)
    if (length(img) > w[typ,3]) w[typ,3] = length(img)
    if (length(cre) > w[typ,4]) w[typ,4] = length(cre)
    if (length(sta) > w[typ,5]) w[typ,5] = length(sta)
}
END {
    hdr[1]="CONTAINER ID"; hdr[2]="NAMES"; hdr[3]="IMAGE"
    hdr[4]="CREATED";      hdr[5]="STATUS"; hdr[6]="PORTS"
    split("standard proxy", types, " ")
    for (ti = 1; ti <= 2; ti++) {
        typ = types[ti]
        if (!(typ in rows)) continue
        for (c = 1; c <= 5; c++) if (length(hdr[c]) > w[typ,c]) w[typ,c] = length(hdr[c])
        fmt = "%-" w[typ,1] "s   %-" w[typ,2] "s   %-" w[typ,3] "s   %-" w[typ,4] "s   %-" w[typ,5] "s   %s\n"
        label = (typ == "proxy") ? "Proxy" : "Standard"
        printf "\n" GREEN "[ " YELLOW label " Applications " GREEN "]" NC " (%d containers)\n\n", cnt[typ]
        printf fmt, hdr[1], hdr[2], hdr[3], hdr[4], hdr[5], hdr[6]
        n = split(rows[typ], lines, "\n")
        for (l = 1; l <= n; l++) {
            if (lines[l] == "") continue
            split(lines[l], f, "\t")
            printf fmt, f[1], f[2], f[3], f[4], f[5], f[6]
        }
    }
}
'
}

CORE_count_table_rows() {
    _n=0
    while IFS= read -r _line; do
        [ -n "$_line" ] && _n=$((_n+1))
    done <<EOF
$1
EOF
    echo "$_n"
}

CORE_start_container() {
    $CONTAINER_ALIAS start "$1" 2>&1
}

CORE_stop_container() {
    $CONTAINER_ALIAS stop -t 0 "$1" 2>&1
}

CORE_restart_container() {
    $CONTAINER_ALIAS restart "$1" 2>&1
}

CORE_remove_container() {
    $CONTAINER_ALIAS rm -f -v "$1" 2>&1
}

CORE_get_container_logs() {
    _name="$1"
    _since="${2:-48h}"
    _logs=$($CONTAINER_ALIAS logs --since "$_since" "$_name" 2>&1)
    if [ -n "$_logs" ]; then
        printf '%s\n' "$_logs"
    else
        $CONTAINER_ALIAS logs "$_name" 2>&1
    fi
}


CORE_expand_containers_by_base() {
    mode=$1; shift
    CORE_UNMATCHED_PROXY=
    if [ -z "$mode" ]; then
        printf '%s' "$*"
        return
    fi
    all_names=$($CONTAINER_ALIAS ps -a --format '{{.Names}}' 2>/dev/null)
    for name in "$@"; do
        case "$mode" in
            all)
                echo "$all_names" | grep -q "^${name}$" && printf '%s ' "$name"
                for matched in $(echo "$all_names" | grep "^${name}-[0-9][0-9]*$" | sort -t '-' -k 2 -n); do
                    printf '%s ' "$matched"
                done
                ;;
            proxy)
                proxy_found=
                for matched in $(echo "$all_names" | grep "^${name}-[0-9][0-9]*$" | sort -t '-' -k 2 -n); do
                    printf '%s ' "$matched"
                    proxy_found=1
                done
                [ -z "$proxy_found" ] && CORE_UNMATCHED_PROXY="$CORE_UNMATCHED_PROXY $name"
                ;;
        esac
    done
}
