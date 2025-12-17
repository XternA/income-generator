#!/bin/sh

# IP Quality Utility Functions

# Detect public IP address with multiple fallbacks
get_real_ip() {
    ip=$(curl -s --connect-timeout 3 --max-time 5 https://api.ipify.org 2>/dev/null)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi

    ip=$(curl -s --connect-timeout 3 --max-time 5 https://ifconfig.me 2>/dev/null)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi

    ip=$(curl -s --connect-timeout 3 --max-time 5 https://icanhazip.com 2>/dev/null)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi

    return 1 # All services failed
}

# Extract IP address from proxy URL
# Input: protocol://user:pass@IP:port
# Output: IP
extract_proxy_ip() {
    proxy_url="$1"

    # Remove protocol: socks5://user:pass@IP:port → user:pass@IP:port
    url="${proxy_url#*://}"

    # Remove credentials: user:pass@IP:port → IP:port
    url="${url#*@}"

    # Extract IP: IP:port → IP
    echo "$url" | cut -d: -f1
}

test_proxy_connectivity() {
    proxy_url="$1"
    
    # Returns the proxy's IP if working, nothing if dead/blocked
    result=$(timeout 5 curl -s -x "$proxy_url" https://api.ipify.org 2>/dev/null)

    # Check if we got a valid IP response
    if [ -n "$result" ] && echo "$result" | grep -Eq '^[0-9.]+$'; then
        echo "$result"
        return 0
    fi

    return 1
}

# Check if IP is on DNS blacklist - Returns 0 if blacklisted, 1 if clean
check_blacklist() {
    ip="$1"

    # Skip if not IPv4 (blacklists don't support IPv6 well)
    echo "$ip" | grep -Eq '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || return 1

    # Reverse IP for DNSBL query (1.2.3.4 → 4.3.2.1)
    reversed_ip=$(echo "$ip" | awk -F. '{print $4"."$3"."$2"."$1}')

    # Query Spamhaus ZEN using Cloudflare DNS-over-HTTPS
    result=$(curl -s -H 'accept: application/dns-json' \
        "https://1.1.1.1/dns-query?name=$reversed_ip.zen.spamhaus.org&type=A" 2>/dev/null)

    # Check if Answer contains 127.0.0.x (indicates blacklisted)
    if echo "$result" | jq -e '.Answer[]? | select(.data | startswith("127.0.0."))' > /dev/null 2>&1; then
        return 0  # Blacklisted
    fi

    return 1  # Clean
}

# Calculate composite fraud score
# Inputs: is_proxy, is_hosting, is_mobile, is_blacklisted, isp_name
# Output: score 0-100
calculate_fraud_score() {
    is_proxy="$1"
    is_hosting="$2"
    is_mobile="$3"
    is_blacklisted="$4"
    isp_name="$5"

    score=0

    # Add points for various risk factors
    [ "$is_proxy" = "true" ] && score=$((score + 40))
    [ "$is_hosting" = "true" ] && score=$((score + 30))
    [ "$is_mobile" = "true" ] && score=$((score + 10))
    [ "$is_blacklisted" = "true" ] && score=$((score + 30))

    # Check for suspicious ISP name patterns
    case "$isp_name" in
        *VPN*|*Proxy*|*Anonymous*|*Private*|*Relay*)
            score=$((score + 15))
            ;;
    esac

    # Cap at 100
    [ "$score" -gt 100 ] && score=100

    echo "$score"
}

# Convert score to rating with color
# Input: score (0-100)
# Output: colored rating text
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

# Format ISP type based on detection flags
# Inputs: is_proxy, is_hosting, is_mobile
# Output: human-readable type
format_isp_type() {
    is_proxy="$1"
    is_hosting="$2"
    is_mobile="$3"

    if [ "$is_proxy" = "true" ]; then
        echo "Proxy/VPN"
    elif [ "$is_hosting" = "true" ]; then
        echo "Datacenter"
    elif [ "$is_mobile" = "true" ]; then
        echo "Mobile"
    else
        echo "Residential"
    fi
}
