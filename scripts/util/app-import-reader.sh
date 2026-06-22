#!/bin/sh

[ -n "$__APP_IMPORT_READER_CACHED" ] && return
__APP_IMPORT_READER_CACHED=1

. scripts/core/apps.sh

TOTAL_APPS=$CORE_TOTAL_APPS
TOTAL_SERVICES=$CORE_TOTAL_SERVICES
APP_PROPERTIES_INDEX=$CORE_APP_PROPERTIES_INDEX
export TOTAL_APPS TOTAL_SERVICES APP_PROPERTIES_INDEX

extract_all_app_data() { CORE_extract_all_app_data "$@"; }
extract_app_data() { CORE_extract_app_data "$@"; }
extract_app_data_fields_only() { CORE_extract_app_data_fields_only "$@"; }
extract_app_data_field() { CORE_extract_app_data_field "$@"; }
extract_and_map_app_data_field() { CORE_extract_and_map_app_data "$@"; }
extract_and_map_single_app_field() { CORE_extract_and_map_single_app "$@"; }

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
