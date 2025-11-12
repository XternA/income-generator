#!/bin/sh

# Cache totals to avoid recomputing on every sourcing
if [ -z "$TOTAL_APPS" ] || [ -z "$TOTAL_SERVICES" ]; then
    __TOTALS=$(jq -r 'length as $total | map(select(has("service_enabled"))) | length as $services | "\($total) \($services)"' "$JSON_FILE")
    TOTAL_APPS=${__TOTALS%% *}
    TOTAL_SERVICES=${__TOTALS##* }
    export TOTAL_APPS TOTAL_SERVICES
fi

__extract_app_data_field() {
    jq -r ".[] | select(has(\"$field_name\")) | \"\(.name) \(.${field_name})\"" "$JSON_FILE"
}

extract_all_app_data() {
    jq -r ".[] | \"\(.name) $(printf ' \(%s)' "$@")\"" "$JSON_FILE"
}

extract_app_data() {
    filter=".is_enabled == true"

    for f in "$@"; do
        if [ "$f" = ".service_enabled" ]; then
            filter="(.is_enabled == true or .service_enabled == true)"
            break
        fi
    done

    jq -r ".[] | select($filter) | \"\(.name) $(printf ' \(%s)' "$@")\"" "$JSON_FILE"
}

extract_app_data_fields_only() {
    app_name="$1"
    shift

    if [ $# -gt 0 ]; then
        field_expr=""
        for field in "$@"; do
            field_expr="$field_expr$field // \"null\" ,"
        done
        field_expr=${field_expr%,}

        jq -r --arg app "$app_name" ".[] | select(.name==\$app) | [$field_expr] | join(\" \")" "$JSON_FILE"
    fi
}

extract_app_data_field() {
    __extract_app_data_field "$1"
}

extract_and_map_app_data_field() {
    file="$JSON_FILE"
    filter=".is_enabled == true"

    # Build mapping expression efficiently
    set -- "$@"  # Save original args
    mapping=""
    separator=""

    for arg; do
        field="${arg%%:*}"
        type="${arg#*:}"
        [ "$field" = "$type" ] && type="string"
        field="${field#.}"

        if [ "$type" = "array" ]; then
            mapping="$mapping$separator\"${field}=\" + ((.${field} // []) | join(\" \") | @sh)"
        else
            mapping="$mapping$separator\"${field}=\" + ((.${field} // \"\") | @sh)"
        fi
        separator=","
    done

    jq -r ".[] | select($filter) | [ $mapping ] | join(\" \")" "$file"
}

display_app_table() {
    data="$1"
    mode="${2:-status}"

    if [ "$mode" = "basic" ]; then
        printf "%-4s %-21s\n" "No." "Name"
        printf "%-4s %-21s\n" "---" "--------------------"
        printf "%s\n" "$data" | awk -v GREEN="$GREEN" -v NC="$NC" '
        BEGIN { counter = 1 } {
            printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
            counter++
        }
        '
    else
        if [ "$mode" = "limit" ]; then
            header_type="Limit"
        elif [ "$mode" = "install" ]; then
            header_type="Type"
        else
            header_type="Status"
        fi

        printf "%-4s %-21s %-8s\n" "No." "Name" "$header_type"
        printf "%-4s %-21s %-8s\n" "---" "--------------------" "--------"

        printf "%s\n" "$data" | awk -v mode="$mode" -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v RED="$RED" -v NC="$NC" '
        BEGIN { counter = 1 } {
            if (mode == "install") {
                if ($3 == "true") {
                    printf "%-4s %s%-21s %s%s\n", counter, GREEN, $1, "App", NC
                    counter++
                }
                if ($2 == "true") {
                    printf "%-4s %s%-21s %s%s\n", counter, YELLOW, $1, "Service", NC
                    counter++
                }
            } else if (mode == "limit") {
                is_null = ($2 == "null" || !$2 || $2 == "-")
                printf "%-4s %-21s %s%s%s\n", counter, $1, is_null ? RED : YELLOW, is_null ? "-" : $2, NC
                counter++
            } else {
                printf "%-4s %-21s %s\n", counter, $1, ($2 == "true") ? GREEN "Enabled" NC : RED "Disabled" NC
                counter++
            }
        }
        '
    fi
}
