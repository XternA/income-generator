#!/bin/sh

[ -n "$__IP_UTIL_CACHED" ] && return
__IP_UTIL_CACHED=1

. scripts/core/network.sh

get_real_ip() {
    CORE_get_real_ip
    echo "$CORE_REAL_IP"
}

extract_proxy_ip() { CORE_extract_proxy_ip "$@"; }
test_proxy_connectivity() { CORE_test_proxy_connectivity "$@"; }
check_blacklist() { CORE_check_blacklist "$@"; }
calculate_fraud_score() { CORE_calculate_fraud_score "$@"; }
format_isp_type() { CORE_format_isp_type "$@"; }

get_score_rating() {
    score="$1"

    if [ "$score" -le 20 ]; then
        printf "${GREEN}Excellent${NC}"
    elif [ "$score" -le 40 ]; then
        printf "${GREEN}Good${NC}"
    elif [ "$score" -le 60 ]; then
        printf "${YELLOW}Medium${NC}"
    elif [ "$score" -le 80 ]; then
        printf "${RED}High${NC}"
    else
        printf "${RED}Critical${NC}"
    fi
}
