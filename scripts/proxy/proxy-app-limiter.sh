#!/bin/sh

[ -n "$__PROXY_APP_LIMITED_CACHED" ] && return
__PROXY_APP_LIMITED_CACHED=1

. scripts/core/proxy.sh

__populate_proxy_limit_entries() {
    CORE_extract_all_app_data .install_limit | awk '{ val = ($2=="null"?"-":$2); print $1 "=" val }' > "$PROXY_INSTALL_LIMIT"
}

__load_limit_data() { CORE_load_limit_data; }

proxy_app_limiter() {
    total_apps=$(awk 'END {print NR}' "$PROXY_INSTALL_LIMIT")

    while true; do
        display_banner
        printf "Applications will not be installed more\nthan the limit if set, default unlimited.\n\n"

        __load_limit_data
        display_app_table "$limit_data" limit

        printf "\nOptions:\n"
        printf "  ${GREEN}r${NC} = ${GREEN}reset all to default${NC}\n"
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

        selected_app=$(awk -F= -v n="$choice" 'NR==n{print $1; exit}' "$PROXY_INSTALL_LIMIT")
        current_value=$(awk -F= -v n="$choice" 'NR==n{print $2; exit}' "$PROXY_INSTALL_LIMIT")
        default_value=$(extract_app_data_fields_only "$selected_app" .install_limit)

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
            if [ "$default_value" != "null" ]; then
                printf "Maximum Limit: ${PINK}%s${NC}\n" "$default_value"
            fi
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
                if [ "$default_value" = "null" ]; then
                    new_value="0"
                else
                    new_value="$default_value"
                fi
            fi

            case "$new_value" in
                ''|*[!0-9]*)
                    printf "\nInvalid input. Enter a whole number only.\n"
                    printf "\nPress Enter to continue..."; read -r _
                    continue
                    ;;
                ''|0*)
                    new_value="-"
                    break
                    ;;
                *)
                    if [ "$new_value" -gt "$default_value" ]; then
                        printf "\nLimit set cannot exceed ${GREEN}$default_value${NC}.\n"
                        printf "\nPress Enter to continue..."; read -r _
                        continue
                    fi
                    ;;
            esac
            break
        done

        tmp_file=$(mktemp)
        awk -F= -v app="$selected_app" -v val="$new_value" 'BEGIN{OFS="="} $1==app{$2=val} {print}' "$PROXY_INSTALL_LIMIT" > "$tmp_file" && mv "$tmp_file" "$PROXY_INSTALL_LIMIT"

        __load_limit_data
    done
}

get_app_install_limit() { CORE_get_app_install_limit "$@"; }
