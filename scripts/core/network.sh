#!/bin/sh

[ -n "$__CORE_NETWORK_CACHED" ] && return
__CORE_NETWORK_CACHED=1

. scripts/core/common.sh

CORE_get_real_ip() {
    CORE_REAL_IP=$(curl -s --connect-timeout 3 --max-time 5 https://api.ipify.org 2>/dev/null)
    [ -n "$CORE_REAL_IP" ] && return 0

    CORE_REAL_IP=$(curl -s --connect-timeout 3 --max-time 5 https://ifconfig.me 2>/dev/null)
    [ -n "$CORE_REAL_IP" ] && return 0

    CORE_REAL_IP=$(curl -s --connect-timeout 3 --max-time 5 https://icanhazip.com 2>/dev/null)
    [ -n "$CORE_REAL_IP" ] && return 0

    CORE_REAL_IP=""
    return 1
}

CORE_extract_proxy_ip() {
    _url="${1#*://}"
    _url="${_url#*@}"
    echo "$_url" | cut -d: -f1
}

CORE_test_proxy_connectivity() {
    _result=$(timeout 5 curl -s -x "$1" https://api.ipify.org 2>/dev/null)

    if [ -n "$_result" ] && echo "$_result" | grep -Eq '^[0-9.]+$'; then
        echo "$_result"
        return 0
    fi
    return 1
}

CORE_check_blacklist() {
    _ip="$1"

    echo "$_ip" | grep -Eq '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || return 1

    _reversed=$(echo "$_ip" | awk -F. '{print $4"."$3"."$2"."$1}')

    _result=$(curl -s -H 'accept: application/dns-json' \
        "https://1.1.1.1/dns-query?name=$_reversed.zen.spamhaus.org&type=A" 2>/dev/null)

    if echo "$_result" | jq -e '.Answer[]? | select(.data | startswith("127.0.0."))' > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

CORE_calculate_fraud_score() {
    _score=0

    [ "$1" = "true" ] && _score=$((_score + 40))   # is_proxy
    [ "$2" = "true" ] && _score=$((_score + 30))   # is_hosting
    [ "$3" = "true" ] && _score=$((_score + 10))   # is_mobile
    [ "$4" = "true" ] && _score=$((_score + 30))   # is_blacklisted

    case "$5" in                                    # isp_name
        *VPN*|*Proxy*|*Anonymous*|*Private*|*Relay*) _score=$((_score + 15)) ;;
    esac

    [ "$_score" -gt 100 ] && _score=100
    echo "$_score"
}


CORE_format_isp_type() {
    if [ "$1" = "true" ]; then echo "Proxy/VPN"
    elif [ "$2" = "true" ]; then echo "Datacenter"
    elif [ "$3" = "true" ]; then echo "Mobile"
    else echo "Residential"
    fi
}
