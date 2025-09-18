#!/bin/sh

__TOTALS=$(jq -r '[.[] | {is_service: has("service_enabled")}]
                 | {total: length, services: map(select(.is_service)) | length}
                 | "\(.total) \(.services)"' "$JSON_FILE")
TOTAL_APPS=${__TOTALS%% *}
TOTAL_SERVICES=${__TOTALS##* }

__extract_app_data_field() {
    jq -r ".[] | select(has(\"$field_name\")) | \"\(.name) \(.${field_name})\"" "$JSON_FILE"
}

extract_all_app_data() {
    jq -r ".[] | \"\(.name) $(printf ' \(%s)' "$@")\"" "$JSON_FILE"
}

extract_app_data() {
    filter=".is_enabled == true"

    for f in "$@"; do
        if [ "$f" = "service_enabled" ]; then
            filter="(.is_enabled == true or .service_enabled == true)"
            break
        fi
    done

    jq -r ".[] | select($filter) | \"\(.name) $(printf ' \(%s)' "$@")\"" "$JSON_FILE"
}

extract_app_data_fields_only() {
    app_name="$1"
    shift
    fields="$*"

    if [ -n "$fields" ]; then
        field_expr=$(printf '%s // "null" ,' $fields)
        field_expr=${field_expr%,}  # strip trailing comma

        jq -r --arg app "$app_name" "$(printf '
            .[] | select(.name==$app) | [%s] | join(" ")
        ' "$field_expr")" "$JSON_FILE"
    fi
}

extract_app_data_field() {
    __extract_app_data_field "$1"
}

display_app_table() {
    data="$1"
    mode="${2:-status}"

    if [ $mode = "basic" ]; then
        printf "%-4s %-21s\n" "No." "Name"
        printf "%-4s %-21s\n" "---" "--------------------"
        printf "%s\n" "$data" | awk -v GREEN="$GREEN" -v NC="$NC" '
        BEGIN { counter = 1 }
        {
            printf "%-4s %s%-21s%s\n", counter, GREEN, $1, NC
            counter++
        }'
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
        BEGIN { counter = 1 }
        {
            if (mode == "install") {
                if ($2 == "true" && $3 == "true") {
                    printf "%-4s %s%-21s %s%s\n", counter, GREEN, $1, "App", NC
                    counter++
                }
                if ($2 == "true") {
                    printf "%-4s %s%-21s %s%s\n", counter, YELLOW, $1, "Service", NC
                } else {
                    printf "%-4s %s%-21s %s%s\n", counter, GREEN, $1, "App", NC
                }
            } else if (mode == "limit") {
                if ($2 == "null" || $2 == "" || $2 == "-") {
                    limit = "-"
                    colour = RED
                } else {
                    limit = $2
                    colour = YELLOW
                }
                printf "%-4s %-21s %s%s%s\n", counter, $1, colour, limit, NC
            } else {
                if ($2 == "true") {
                    status = GREEN "Enabled" NC
                } else {
                    status = RED "Disabled" NC
                }
                printf "%-4s %-21s %s\n", counter, $1, status
            }
            counter++
        }'
    fi
}
