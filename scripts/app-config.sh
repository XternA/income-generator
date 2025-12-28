#!/bin/sh

[ -n "$__APP_CONFIG_CACHED" ] && return
__APP_CONFIG_CACHED=1

. scripts/util/uuid-generator.sh
. scripts/util/app-import-reader.sh

display_banner() {
    clear
    printf "Income Generator Credentials Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n"
}

__reorder_config_file() {
    # Skip if empty or doesn't exist
    [ -s "$ENV_FILE" ] || return 0

    # Lazy load metadata only when needed (cached for session)
    if [ -z "$ordered_app_metadata" ]; then
        ordered_app_metadata=$(jq -r 'to_entries | map({
            name: .value.name,
            props: (.value.properties // [] | map(ltrimstr("#")) | join(",")),
            order: .key
        }) | .[] | "\(.name)|\(.props)|\(.order)"' "$JSON_FILE")
    fi

    # Exit early if file already correctly ordered
    expected_order=$(printf '%s\n' "$ordered_app_metadata" | awk -F'|' '{apps = apps (apps ? "," : "") $1} END {print apps}')

    awk -F'=' -v exp="$expected_order" '
    /^[A-Z_]+=[^[:space:]]/ {
        split($1, parts, "_")
        if (parts[1] != prev && parts[1] != "") {
            apps = apps (apps ? "," : "") parts[1]
            prev = parts[1]
        }
    }
    END { exit (apps == exp ? 0 : 1) }
    ' "$ENV_FILE" && return 0

    TEMP_ENV=".igm_config_reorg_$$"
    trap 'rm -f "$TEMP_ENV"; exit' INT TERM EXIT

    printf '%s\n' "$ordered_app_metadata" | awk -F'|' -v envfile="$ENV_FILE" '
        # Phase 1: Build metadata lookup tables
        {
            app = $1
            split($2, prop_arr, ",")
            app_props[app] = $2
            app_order[app] = $3

            # Build reverse mapping: property → app
            for (i in prop_arr) {
                if (prop_arr[i] != "") {
                    prop_to_app[prop_arr[i]] = app
                }
            }
        }

        END {
            # Phase 2: Parse config file and group credentials by app
            while ((getline line < envfile) > 0) {
                if (line ~ /^[A-Z_]+=[^[:space:]]/) {
                    idx = index(line, "=")
                    key = substr(line, 1, idx - 1)
                    value = substr(line, idx + 1)

                    # Determine app ownership
                    if (key in prop_to_app) {
                        app = prop_to_app[key]
                    } else {
                        # Fallback: prefix before first underscore
                        split(key, parts, "_")
                        app = parts[1]
                    }

                    # Store credential grouped by app (ternary for conciseness)
                    app_creds[app] = (app in app_creds) ? app_creds[app] "\n" key "=" value : key "=" value
                    app_has_creds[app] = 1
                }
            }
            close(envfile)

            # Phase 3: Output in apps.json order
            max_order = 0
            for (app in app_order) {
                ordered[app_order[app]] = app
                max_order = (app_order[app] > max_order) ? app_order[app] : max_order
            }

            first_app = 1
            for (i = 0; i <= max_order; i++) {
                if (!(i in ordered)) continue
                app = ordered[i]

                # Skip if no credentials or no properties defined
                if (!(app in app_has_creds) || app_props[app] == "") continue

                # Add blank line separator (except first app)
                if (!first_app) print ""
                first_app = 0

                # Split properties and credentials for this app
                n_props = split(app_props[app], props, ",")
                n_creds = split(app_creds[app], creds, "\n")

                # Build credential lookup map
                delete cred_map
                for (j = 1; j <= n_creds; j++) {
                    idx = index(creds[j], "=")
                    cred_key = substr(creds[j], 1, idx - 1)
                    cred_val = substr(creds[j], idx + 1)
                    cred_map[cred_key] = cred_val
                }

                # Output properties in apps.json order
                for (j = 1; j <= n_props; j++) {
                    if (props[j] in cred_map)
                        print props[j] "=" cred_map[props[j]]
                }

                # Mark as processed
                delete app_has_creds[app]
            }

            # Phase 4: Output orphaned apps
            for (app in app_has_creds) {
                if (!first_app) print ""
                first_app = 0
                print ""
                print app_creds[app]
            }
        }
    ' > "$TEMP_ENV"

    mv "$TEMP_ENV" "$ENV_FILE"
    rm -f "$TEMP_ENV"
}

write_entry() {
    if [ "$is_update" = true ]; then
        awk -v entry="$entry_name" -v input="$input" -F "=" 'BEGIN { OFS="=" } $1 == entry { $2 = input } 1' "$ENV_FILE" >"$ENV_FILE.tmp"
        mv "$ENV_FILE.tmp" "$ENV_FILE"
    else
        if [ ! -s "$ENV_FILE" ]; then
            echo "$entry_name=$input" >"$ENV_FILE"
        else
            [ "$is_new_app" = true ] && {
                echo "" >> "$ENV_FILE"
                is_new_app=false
            }
            echo "$entry_name=$input" >>"$ENV_FILE"
        fi
    fi
}

input_new_value() {
    printf "Enter a new value for $RED$entry_name$NC (or press Enter to skip): "; read -r input < /dev/tty
    [ -n "$input" ] && write_entry
}

process_new_entry() {
    if [ "$entry" != "$entry_name" ]; then
        input="$(generate_uuid $uuid_type)"
        write_entry
        printf "A new UUID has been auto-generated for $RED$entry_name$NC: $YELLOW$input$NC\n\n"
        [ -n "$registration" ] && printf "${YELLOW}$registration$input${NC}\n\n"
        printf "Press Enter to continue..."; read -r input </dev/tty
    else
        input_new_value
    fi
}

process_uuid_user_choice() {
    printf "Do you want to auto-generate a new UUID for $RED$entry_name$NC? (Y/N): "; read -r input < /dev/tty
    case "$input" in
        [yY]) process_new_entry ;;
        *)
            printf "Do you want to define an existing UUID? (Y/N): "; read -r input < /dev/tty
            case "$input" in
                [yY])
                    input_new_value
                    break
                    ;;
            esac
            ;;
    esac
}

process_entries() {
    app_data=$(extract_and_map_app_data_field .name .is_enabled .service_enabled .url .description .description_ext .registration .properties:array .uuid_type)
    total_enabled_apps=$(printf '%s\n' "$app_data" | awk 'NF{n++} END{print n+0}')

    if [ "$total_enabled_apps" -eq 0 ]; then
        display_banner
        printf "\n${YELLOW}No applications currently enabled.${NC}\n\n"
        printf "Please select and enable applications first\nto configure their credentials.\n"
        return
    fi

    : > "$REF_FILE"
    existing_entries=$([ -f "$ENV_FILE" ] && awk -F '=' '{print $1}' "$ENV_FILE" | tr '\n' '|')

    printf '%s\n' "$app_data" | while IFS= read -r config_entry; do
        eval "$config_entry" || continue

        [ "$is_enabled" = "false" ] && [ "$service_enabled" != "true" ] && continue
        entry_count=$((entry_count + 1))
        is_new_app=true

        display_banner
        printf "\nTotal applications: ${RED}$TOTAL_APPS${NC}\n"
        printf "\nConfiguring application ${RED}$entry_count${NC} of ${RED}$total_enabled_apps${NC}\n"
        printf "\n[ ${GREEN}$name${NC} ]\n"
        [ -n "$url" ] && printf "Go to $BLUE$url$NC to register an account. (CTRL + Click)\n"
        [ -n "$description" ] && printf "Description: ${YELLOW}$description${NC}\n"
        [ -n "$description_ext" ] && printf "${YELLOW}$description_ext${NC}\n"
        echo

        if [ -n "$properties" ]; then
            for entry in $properties; do
                case "$entry" in
                    "#"*)
                        require_uuid="#"
                        entry_name="${entry#\#}"
                        ;;
                    *)
                        require_uuid=""
                        entry_name="$entry"
                        ;;
                esac

                is_update=false
                case "|$existing_entries|" in
                    *"|$entry_name|"*) is_update=true ;;
                esac

                [ "$require_uuid" = "#" ] && process_uuid_user_choice || input_new_value
            done
        else
            printf "Press Enter to continue..."; read -r _ < /dev/tty
        fi
    done

    display_banner
    if [ "$ENV_FILE" -nt "$REF_FILE" ]; then
        __reorder_config_file
        printf "\n${YELLOW}Done configuring config file.${NC}\n"
    else
        printf "\n${RED}No changes made to config file.${NC}\n"
    fi
    rm -f "$REF_FILE"
}

configure_app_inline() {
    app_name="$1"

    app_data=$(extract_and_map_single_app_field "$app_name" .name .url .description .description_ext .properties:array .uuid_type .registration)
    eval "$app_data"

    : > "$REF_FILE"

    display_banner
    printf "\nSetting up credentials for...\n"
    printf "\n[ ${GREEN}$name${NC} ]\n"
    [ -n "$url" ] && printf "Go to ${BLUE}$url${NC} to register an account. (CTRL + Click)\n"
    [ -n "$description" ] && printf "Description: ${YELLOW}$description${NC}\n"
    [ -n "$description_ext" ] && printf "${YELLOW}$description_ext${NC}\n"
    echo

    if [ -n "$properties" ]; then
        existing_entries=$([ -f "$ENV_FILE" ] && awk -F '=' '{print $1}' "$ENV_FILE" | tr '\n' '|')

        for entry in $properties; do
            case "$entry" in
                "#"*)
                    require_uuid="#"
                    entry_name="${entry#\#}"
                    ;;
                *)
                    require_uuid=""
                    entry_name="$entry"
                    ;;
            esac

            is_update=false
            case "|$existing_entries|" in
                *"|$entry_name|"*) is_update=true ;;
            esac

            [ "$require_uuid" = "#" ] && process_uuid_user_choice || input_new_value
        done
    fi

    if [ "$ENV_FILE" -nt "$REF_FILE" ]; then
        __reorder_config_file
        printf "\nDone configuring ${GREEN}$name${NC}.\n"
    else
        printf "\n${GREEN}$name${NC} not configured.\n"
    fi
    rm -f "$REF_FILE"

    printf "\nPress Enter to continue..."; read -r _ < /dev/tty
    return 0
}

# Main script
REF_FILE=".igm_config_ref_$$"
trap 'rm -f $REF_FILE' INT

[ ! -f "$ENV_FILE" ] && : > "$ENV_FILE"

if [ "$1" = "--config" ] && [ -n "$2" ]; then
    configure_app_inline "$2"
else
    printf "Start application setup process? (Y/N): "; read -r input
    case "$input" in
        [yY]) process_entries ;;
        *) printf "\n${RED}No changes made to config file.${NC}\n" ;;
    esac
    printf "\nPress Enter to continue..."; read -r _ < /dev/tty
fi
