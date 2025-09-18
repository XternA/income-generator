#!/bin/sh)

__populate_proxy_limit_entries() {
    extract_all_app_data .install_limit | awk '{ val = ($2=="null"?"-":$2); print $1 "=" val }' > "$PROXY_INSTALL_LIMIT"
}

__load_limit_data() {
    limit_data=$(awk -F= '{print $1, $2}' "$PROXY_INSTALL_LIMIT")
}

proxy_app_limiter() {
    total_apps=$(awk 'END {print NR}' "$PROXY_INSTALL_LIMIT")

    while true; do
        display_banner
        printf "Proxy Application Limiter\n\n"

        __load_limit_data
        display_app_table "$limit_data" limit

        printf "\nOptions:\n"
        printf "  ${GREEN}r${NC} = ${GREEN}default all${NC}\n"
        printf "  ${RED}0${NC} = ${RED}exit${NC}\n"
        printf "\nSelect application to apply limit (1-$total_apps): "; read -r choice

        case "$choice" in
            0) break ;;
            r)
                __populate_proxy_limit_entries
                continue
                ;;
            ''|*[!0-9]*)
                printf "\nInvalid input. Enter a number between 1 and $total_apps.\n"
                printf "\nPress Enter to continue..."; read -r _
                continue
                ;;

            *)
                if [ "$choice" -lt 1 ] || [ "$choice" -gt "$total_apps" ]; then
                    printf "\nInvalid input. Enter a number between 1 and $total_apps.\n"
                    printf "\nPress Enter to continue..."; read -r _
                    continue
                fi
                ;;
        esac

        selected_app=$(printf '%s\n' "$limit_data" | awk -v n="$choice" 'NR==n {print $1}')
        current_value=$(awk -F= -v app="$selected_app" '$1 == app {print $2}' "$PROXY_INSTALL_LIMIT")
        if [ "$current_value" = "-" ]; then
            display_current_value="Unlimited"
        else
            display_current_value="$current_value"
        fi

        while true; do
            display_banner
            printf "Configuring proxy install count limit.\n\n"
            printf "Application:   ${GREEN}%s${NC}\n" "$selected_app"
            printf "Current Limit: ${YELLOW}%s${NC}\n" "$display_current_value"
            printf "\nOptions:\n  ${RED}0${NC} = ${RED}reset to default${NC}\n"
            printf "\nPress Enter to keep current setting.\n"
            printf "\nEnter new limit: "; read -r new_value

            # Keep current if blank
            if [ -z "$new_value" ]; then
                new_value="$current_value"
                break
            fi

            # Reset to default
            if [ "$new_value" = "0" ]; then
                default_value=$(extract_app_data_fields_only "$selected_app" .install_limit)
                if [ "$default_value" = "null" ]; then
                    new_value="0"
                else
                    new_value="$default_value"
                fi
            fi

            case "$new_value" in
                *[!0-9]*)
                    printf "\nInvalid input. Enter limit in number quantity only.\n"
                    printf "\nPress Enter to continue..."; read -r _
                    continue
                    ;;
                ''|0*)
                    new_value="-"
                    break
                    ;;
            esac

            # trim leading zeros
            trimmed_value=$(printf '%s' "$new_value" | sed 's/^0*\([1-9][0-9]*\)$/\1/')
            [ -z "$trimmed_value" ] && trimmed_value="0"
            new_value="$trimmed_value"
            break
        done

        tmp_file=$(mktemp)
        awk -F= -v app="$selected_app" -v val="$new_value" 'BEGIN{OFS="="} $1==app{$2=val} {print}' "$PROXY_INSTALL_LIMIT" > "$tmp_file" && mv "$tmp_file" "$PROXY_INSTALL_LIMIT"

        __load_limit_data
    done
}

get_app_install_limit() {
    search_app="$1"
    set -- $limit_data

    # normalise search string once
    search_app_uc=$(printf '%s' "$search_app" | tr '[:lower:]' '[:upper:]')

    while [ $# -gt 0 ]; do
        app="$1"
        val="$2"
        app_uc=$(printf '%s' "$app" | tr '[:lower:]' '[:upper:]')
        if [ "$app_uc" = "$search_app_uc" ]; then
            case "$val" in
                ""|-) echo "null" ;;
                *) echo "$val" ;;
            esac
            return 0
        fi
        shift 2
    done
}

# Init
if [ ! -f "$PROXY_INSTALL_LIMIT" ]; then
    __populate_proxy_limit_entries
else
    tmp_file=$(mktemp)
    tmp_source=$(mktemp)

    extract_all_app_data .install_limit | awk '{print $1, $2}' > "$tmp_source"

    awk '
        BEGIN { OFS="=" }
        # Read old file (key=value)
        FNR==NR { split($0, a, "="); old[a[1]]=a[2]; next }
        # Read source (key value)
        {
            key = $1
            val = ($2 == "null" ? "-" : $2)
            if (key in old) {
                print key, old[key]
            } else {
                print key, val
            }
        }
    ' "$PROXY_INSTALL_LIMIT" "$tmp_source" > "$tmp_file"

    mv "$tmp_file" "$PROXY_INSTALL_LIMIT"
    rm -f "$tmp_source"
fi
__load_limit_data
