#!/bin/sh

. scripts/shared-component.sh
. scripts/ip/ip-util.sh

display_banner() {
    clear
    printf "Income Generator IP Quality Tool\n"
    printf "${GREEN}------------------------------------------${NC}\n\n"
}

main() {
    display_banner
    
    printf "Detecting your public IP address...\n"
    REAL_IP=$(get_real_ip)

    if [ -z "$REAL_IP" ]; then
        printf "${RED}Error: Unable to detect public IP. Check internet connection.${NC}\n"
        exit 1
    fi

    printf "Real IP: ${GREEN}$REAL_IP${NC}\n\n"

    # Check for proxy file
    HAS_PROXIES="false"
    PROXY_COUNT=0

    if [ -f "$PROXY_FILE" ]; then
        # Count active proxies only
        PROXY_COUNT=$(grep -c '^[^#]' "$PROXY_FILE" 2>/dev/null || echo 0)

        if [ "$PROXY_COUNT" -gt 0 ]; then
            HAS_PROXIES="true"
            printf "Found ${GREEN}$PROXY_COUNT${NC} active proxies to analyse.\n\n"
        fi
    fi

    if [ "$HAS_PROXIES" = "false" ]; then
        printf "${YELLOW}Note: No active proxies found. Analysing real IP only.${NC}\n\n"
    fi

    # Test proxy connectivity if we have proxies
    WORKING_PROXIES=""
    WORKING_COUNT=0
    PROXY_IPS=""

    if [ "$HAS_PROXIES" = "true" ]; then
        printf "Testing proxy connectivity:\n"

        counter=1
        while IFS= read -r proxy_url; do
            # Skip commented lines
            case "$proxy_url" in
                \#*|"") continue ;;
            esac

            # Test connectivity - cache IP extraction
            proxy_ip=$(extract_proxy_ip "$proxy_url")
            printf "  [%s/%s] Testing %-15s  " "$counter" "$PROXY_COUNT" "$proxy_ip"

            if test_proxy_connectivity "$proxy_url" > /dev/null 2>&1; then
                printf "${GREEN}ALIVE${NC}\n"
                WORKING_PROXIES="${WORKING_PROXIES}${proxy_url}|"
                PROXY_IPS="${PROXY_IPS}${proxy_ip}|"
                WORKING_COUNT=$((WORKING_COUNT + 1))
            else
                printf "${RED}DEAD${NC}\n"
            fi

            counter=$((counter + 1))
        done < "$PROXY_FILE"

        printf "\nWorking proxies: ${GREEN}${WORKING_COUNT}/${PROXY_COUNT}${NC}\n\n"
    fi

    # Build batch API query
    printf "Fetching IP quality data...\n"

    # Build JSON array for batch request
    batch_json="[{\"query\":\"$REAL_IP\",\"fields\":\"status,country,city,isp,org,proxy,hosting,mobile\"}"

    if [ "$WORKING_COUNT" -gt 0 ]; then
        # Remove trailing pipe
        proxy_ips_clean="${PROXY_IPS%|}"

        # Split by pipe and add to batch
        IFS='|'
        for ip in $proxy_ips_clean; do
            batch_json="${batch_json},{\"query\":\"$ip\",\"fields\":\"status,country,city,isp,org,proxy,hosting,mobile\"}"
        done
        unset IFS
    fi

    batch_json="${batch_json}]"

    # Query API
    api_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$batch_json" \
        "http://ip-api.com/batch" 2>/dev/null)

    case "$api_response" in
        ""|*'"status":"fail"'*)
            printf "${RED}Error: API request failed. Check internet or try again later.${NC}\n"
            exit 1
            ;;
        *)
            printf "${GREEN}Data fetched successfully.${NC}\n\n"
            ;;
    esac

    printf "Checking DNS blacklists:\n"

    # Check real IP
    printf "  Checking %-15s  " "$REAL_IP"
    if check_blacklist "$REAL_IP"; then
        REAL_IP_BLACKLIST="true"
        printf "${RED}LISTED${NC}\n"
    else
        REAL_IP_BLACKLIST="false"
        printf "${GREEN}CLEAN${NC}\n"
    fi

    # Check proxy IPs
    PROXY_BLACKLISTS=""
    if [ "$WORKING_COUNT" -gt 0 ]; then
        proxy_ips_clean="${PROXY_IPS%|}"
        IFS='|'
        for ip in $proxy_ips_clean; do
            printf "  Checking %-15s  " "$ip"
            if check_blacklist "$ip"; then
                PROXY_BLACKLISTS="${PROXY_BLACKLISTS}true|"
                printf "${RED}LISTED${NC}\n"
            else
                PROXY_BLACKLISTS="${PROXY_BLACKLISTS}false|"
                printf "${GREEN}CLEAN${NC}\n"
            fi
        done
        unset IFS
    fi

    # Calculate dynamic location column width based on actual data
    max_loc_len=8  # Minimum for "Location" header

    # Include real IP location
    real_location="$real_city, $real_country"
    real_loc_len=${#real_location}
    [ "$real_loc_len" -gt "$max_loc_len" ] && max_loc_len="$real_loc_len"

    # Scan all proxy locations (first pass through data)
    if [ "$WORKING_COUNT" -gt 0 ]; then
        proxy_idx=1
        proxy_ips_clean="${PROXY_IPS%|}"

        IFS='|'
        for proxy_ip in $proxy_ips_clean; do
            # Extract location from API response
            loc_data=$(echo "$api_response" | jq -r ".[$proxy_idx] | [.city // \"Unknown\", .country // \"Unknown\"] | @tsv")

            # Parse city and country
            IFS='	'
            set -- $loc_data
            loc_city="$1"
            loc_country="$2"
            unset IFS

            # Format and measure
            loc_string="$loc_city, $loc_country"
            loc_len=${#loc_string}
            [ "$loc_len" -gt "$max_loc_len" ] && max_loc_len="$loc_len"

            proxy_idx=$((proxy_idx + 1))
        done
        unset IFS
    fi

    # Apply constraints to prevent extreme widths
    MIN_LOC_WIDTH=12  # Minimum readable width
    MAX_LOC_WIDTH=35  # Prevent excessive line wrapping

    if [ "$max_loc_len" -lt "$MIN_LOC_WIDTH" ]; then
        LOC_WIDTH="$MIN_LOC_WIDTH"
    elif [ "$max_loc_len" -gt "$MAX_LOC_WIDTH" ]; then
        LOC_WIDTH="$MAX_LOC_WIDTH"
    else
        LOC_WIDTH="$max_loc_len"
    fi

    # Add padding for visual breathing room
    LOC_WIDTH=$((LOC_WIDTH + 2))

    # Calculate total table width dynamically
    # Format: %-4s %-17s %-6s %-12s %-${LOC_WIDTH}s %-10s
    # Columns: #(4) + space(1) + IP(17) + space(1) + Risk(6) + space(1) +
    #          Type(12) + space(1) + Location(LOC_WIDTH) + space(1) + Blacklist(10)
    TABLE_WIDTH=$((4 + 1 + 17 + 1 + 6 + 1 + 12 + 1 + LOC_WIDTH + 1 + 10))

    # Generate banner dynamically using printf and tr
    TABLE_BANNER=$(printf "%${TABLE_WIDTH}s" "" | tr ' ' '=')

    # Generate location separator dashes
    LOC_DASHES=$(printf "%${LOC_WIDTH}s" "" | tr ' ' '-')

    # Display results
    printf "\n%s\n" "$TABLE_BANNER"
    printf "Real IP Analysis: ${BLUE}$REAL_IP${NC}\n"
    printf "%s\n" "$TABLE_BANNER"

    # Parse real IP data (first entry in array)
    real_data=$(echo "$api_response" | jq -r '.[0] | [.country // "Unknown", .city // "Unknown", .isp // "Unknown", (.proxy // false), (.hosting // false), (.mobile // false)] | @tsv')

    # Split tab-separated values into variables
    IFS='	'  # Tab character
    set -- $real_data
    real_country="$1"
    real_city="$2"
    real_isp="$3"
    real_is_proxy="$4"
    real_is_hosting="$5"
    real_is_mobile="$6"
    unset IFS

    # Calculate score
    real_score=$(calculate_fraud_score "$real_is_proxy" "$real_is_hosting" "$real_is_mobile" "$REAL_IP_BLACKLIST" "$real_isp")
    real_rating=$(get_score_rating "$real_score")
    real_type=$(format_isp_type "$real_is_proxy" "$real_is_hosting" "$real_is_mobile")

    # Display real IP info
    printf "Fraud Risk:   ${BLUE}$real_score/100${NC} ($real_rating)\n"
    printf "Location:     ${BLUE}$real_city, $real_country${NC}\n"
    printf "ISP:          ${BLUE}$real_isp${NC}\n"
    printf "Type:         ${BLUE}$real_type${NC}\n"

    if [ "$REAL_IP_BLACKLIST" = "true" ]; then
        printf "Blacklist:    ${RED}Listed ✗${NC}\n"
    else
        printf "Blacklist:    ${GREEN}Clean ✓${NC}\n"
    fi

    printf "\n"

    # Display proxy analysis if we have working proxies
    if [ "$WORKING_COUNT" -gt 0 ]; then
        printf "%s\n" "$TABLE_BANNER"
        printf "Proxy Analysis (${GREEN}${WORKING_COUNT}${NC} working)\n"
        printf "%s\n" "$TABLE_BANNER"
        printf "%-4s %-17s %-6s %-12s %-${LOC_WIDTH}s %-10s\n" "#" "IP Address" "Risk" "Type" "Location" "Blacklist"
        printf "%-4s %-17s %-6s %-12s %-${LOC_WIDTH}s %-10s\n" "---" "----------------" "-----" "-----------" "$LOC_DASHES" "---------"

        # Process each proxy
        proxy_counter=1
        total_score=0
        proxy_ips_clean="${PROXY_IPS%|}"
        proxy_bl_clean="${PROXY_BLACKLISTS%|}"

        IFS='|'
        set -- $proxy_ips_clean
        proxy_count=$#

        for proxy_ip in $proxy_ips_clean; do
            # Get corresponding data from API response (offset by 1 since real IP is first)
            proxy_data=$(echo "$api_response" | jq -r ".[$proxy_counter] | [.country // \"Unknown\", .city // \"Unknown\", .isp // \"Unknown\", (.proxy // false), (.hosting // false), (.mobile // false)] | @tsv")

            # Split tab-separated values into variables
            IFS='	'  # Tab character
            set -- $proxy_data
            p_country="$1"
            p_city="$2"
            p_isp="$3"
            p_is_proxy="$4"
            p_is_hosting="$5"
            p_is_mobile="$6"
            unset IFS

            # Get blacklist status for this proxy
            p_blacklist=$(printf '%s' "$proxy_bl_clean" | cut -d'|' -f$proxy_counter)

            # Calculate score
            p_score=$(calculate_fraud_score "$p_is_proxy" "$p_is_hosting" "$p_is_mobile" "$p_blacklist" "$p_isp")
            p_type=$(format_isp_type "$p_is_proxy" "$p_is_hosting" "$p_is_mobile")
            p_location="$p_city, $p_country"

            # Format blacklist status
            if [ "$p_blacklist" = "true" ]; then
                bl_status="${RED}Listed ✗${NC}"
            else
                bl_status="${GREEN}Clean ✓${NC}"
            fi

            # Display row
            printf "%-4s %-17s ${BLUE}%-6s${NC} %-12s %-${LOC_WIDTH}s %b\n" \
                "$proxy_counter" "$proxy_ip" "$p_score" "$p_type" "$p_location" "$bl_status"

            # Track total for average
            total_score=$((total_score + p_score))
            proxy_counter=$((proxy_counter + 1))
        done
        unset IFS

        # Calculate average
        if [ "$WORKING_COUNT" -gt 0 ]; then
            avg_score=$((total_score / WORKING_COUNT))
            avg_rating=$(get_score_rating "$avg_score")
            printf "\nAverage proxy fraud risk: ${BLUE}$avg_score/100${NC} ($avg_rating)\n"
        fi

        printf "\n"
    fi

    printf "Press Enter to continue..."; read -r input
}

# Bootstrap
main
