#!/bin/sh

[ -n "$__APP_MANAGER_CACHED" ] && return
__APP_MANAGER_CACHED=1

. scripts/util/app-import-reader.sh
. scripts/util/app-credential-validator.sh

WATCHTOWER="sh $ROOT_DIR/scripts/runtime/watchtower.sh"

LOADED_ENV_FILES="
$SYSTEM_ENV_FILES
--env-file $ENV_DEPLOY_FILE
"

APP_COMPOSE_FILES="
-f $COMPOSE_DIR/compose.unlimited.yml
-f $COMPOSE_DIR/compose.hosting.yml
-f $COMPOSE_DIR/compose.local.yml
-f $COMPOSE_DIR/compose.single.yml
-f $COMPOSE_DIR/compose.service.yml
"

ALL_COMPOSE_FILES="
-f $COMPOSE_DIR/compose.yml
$APP_COMPOSE_FILES
"

load_app_service_data() {
    app_data=$(extract_app_data .service_enabled .is_enabled)
    has_apps_services=$(echo "$app_data" | awk '{if ($2 == "true" || $3 == "true") {print "true"; exit}}')
}

print_total_apps_info() {
    printf "Total Available:\n ${GREEN}Applications: ${RED}${TOTAL_APPS}${NC} | ${YELLOW}Services: ${RED}${TOTAL_SERVICES}${NC}\n\n"
}

display_install_info() {
    display_banner

    local is_reinstall_state="$1"

    install_type="installed"
    [ "$is_reinstall_state" = "redeploy" ] && install_type="redeployed"

    load_app_service_data

    [ "$is_reinstall_state" != "redeploy" ] && print_total_apps_info

    if [ -z "$has_apps_services" ]; then
        can_install="false"

        if [ "$is_reinstall_state" = "redeploy" ]; then
            printf "No save state to redeploy from.\nInstall normally to save state first.\n"
        else
            printf "No applications/services currently selected to ${install_type}.\n"
        fi
    else
        printf "The following applications will be ${install_type}.\n\n"

        display_app_table "$app_data" install
        can_install="true"
    fi

    printf "\nOption:\n"
    if [ "$is_reinstall_state" != "redeploy" ]; then
        printf "  ${GREEN}a${NC} = ${GREEN}select applications${NC}\n"
        printf "  ${YELLOW}s${NC} = ${YELLOW}select services${NC}\n"
    else
        if [ "$can_install" = "true" ]; then
            printf "  ${RED}c${NC} = ${RED}clear redeploy state${NC}\n"
        fi
    fi

    if [ "$can_install" = "false" ]; then
        if [ "$is_reinstall_state" = "redeploy" ]; then
            printf "\nPress Enter to quit. "
        else
            printf "\nSelect an option or press Enter to return: "
        fi
    else
        printf "\nDo you want to proceed? (Y/N): "
    fi
    read -r input
}

install_applications() {
    display_apps_services() {
        load_app_service_data
        print_total_apps_info

        if [ -z "$has_apps_services" ]; then
            echo "No applications/services currently selected to install."
            can_install="false"
        else
            printf "The following applications will be installed.\n\n"

            display_app_table "$app_data" install
            can_install="true"
        fi

        printf "\nOption:\n"
        printf "  ${GREEN}a${NC} = ${GREEN}select applications${NC}\n"
        printf "  ${YELLOW}s${NC} = ${YELLOW}select services${NC}\n\n"

        if [ "$can_install" = "false" ]; then
            printf "Select an option or press Enter to return: "
        else
            printf "Do you want to proceed? (Y/N): "
        fi
        read -r input
    }

    while true; do
        display_banner
        [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

        if [ "$1" = "quick_menu" ]; then
            printf "How would you like to install?\n\n"
            exit_option="0. Exit"
        else
            exit_option="0. Return to Main Menu"
        fi
        is_selective=false

        options="(1-4)"

        echo "1. Selective applications"
        echo "2. All applications available"
        echo "3. Only VPS/Hosting applications"
        echo "4. All service applications"
        echo "$exit_option"

        printf "\nSelect an option $options: "; read -r option
        case "$option" in
            1)
                while true; do
                    display_install_info

                    case "$input" in
                        "")
                            break
                            ;;
                        [Yy])
                            if [ "$can_install" = "true" ]; then
                                install_type="Installing selective applications..."
                                compose_files=$ALL_COMPOSE_FILES
                                is_selective=true
                                break
                            fi
                            printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                            ;;
                        [Nn])
                            if [ "$can_install" = "true" ]; then
                                compose_files=""
                                break
                            fi
                            printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                            ;;
                        a)
                            $APP_SELECTION
                            ;;
                        s)
                            $APP_SELECTION service
                            ;;
                        *)
                            printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                            ;;
                    esac
                done
                ;;
            2)
                install_type="Installing all applications..."
                compose_files=$ALL_COMPOSE_FILES
                ;;
            3)
                install_type="Installing only applications supporting VPS/Hosting..."
                compose_files="-f $COMPOSE_DIR/compose.yml -f $COMPOSE_DIR/compose.unlimited.yml -f $COMPOSE_DIR/compose.hosting.yml"
                ;;
            4)
                install_type="Installing all available services application..."
                compose_files="-f $COMPOSE_DIR/compose.yml -f $COMPOSE_DIR/compose.service.yml"
                ;;
            0)
                break
                ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac

        # Skip installation if no valid option was chosen
        [ -z "$compose_files" ] && continue

        display_banner
        if [ ! -s "$ENV_FILE" ]; then
            printf "No configuration for applications found. Configure app credentials first.\n"
            printf "Running setup configuration now...\n\n"
            sleep 0.6
            $APP_CONFIG
            return
        fi

        printf "Pulling latest image...\n\n"
        [ "$is_selective" = false ] && { $APP_SELECTION --backup > /dev/null 2>&1; $APP_SELECTION --default > /dev/null 2>&1; }

        proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=$IGM_PROXY_PROJECT_LABEL" | head -n 1)"
        [ "$proxy_is_active" ] && $WATCHTOWER modify_only

        $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $compose_files pull
        echo
        $CONTAINER_ALIAS container prune -f --filter "label=$IGM_PROJECT_LABEL"
        sleep 1.5

        display_banner
        printf "$install_type\n\n"
        $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $compose_files up --force-recreate --build -d
        [ "$is_selective" = false ] && $APP_SELECTION --restore > /dev/null 2>&1
        $APP_SELECTION --save > /dev/null 2>&1
        $WATCHTOWER restore_only

        printf "\nPress Enter to continue..."; read -r input
    done
}

reinstall_applications() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    $APP_SELECTION --backup > /dev/null 2>&1
    $APP_SELECTION --restore redeploy > /dev/null 2>&1

    while true; do
        display_install_info redeploy

        case "$can_install" in
            false) break ;;
        esac

        case "$input" in
            "")
                break
                ;;
            [Yy])
                display_banner
                printf "Pulling latest image...\n\n"

                proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=$IGM_PROXY_PROJECT_LABEL" | head -n 1)"
                [ "$proxy_is_active" ] && $WATCHTOWER modify_only

                $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $ALL_COMPOSE_FILES pull
                echo
                $CONTAINER_ALIAS container prune -f --filter "label=$IGM_PROJECT_LABEL"
                sleep 1.5

                display_banner
                printf "Redeploying last application install state...\n\n"
                $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $ALL_COMPOSE_FILES up --force-recreate --build -d
                [ "$proxy_is_active" ] && $WATCHTOWER restore_only

                printf "\nPress Enter to continue..."; read -r input
                break
                ;;
            [Nn])
                break
                ;;
            c)
                rm -f "$ENV_DEPLOY_FILE.save"
                printf "\nRedeploy save state has been cleared.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
            *)
                printf "\nInvalid option.\n\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
    $APP_SELECTION --restore > /dev/null 2>&1
}

start_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Starting applications...\n\n"
    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES start
    printf "\nAll installed applications started.\n"
    printf "\nPress Enter to continue..."; read -r input
}

start_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    result="$($CONTAINER_ALIAS start "$1" 2>&1)"
    if [ "$result" = "$1" ]; then
        printf "Starting application ${RED}$1${NC}\n"
    else
        printf "Failed to start application ${RED}$1${NC}\n$result\n"
    fi
}

stop_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Stopping applications...\n\n"

    compose_files=$ALL_COMPOSE_FILES
    proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=$IGM_PROXY_PROJECT_LABEL" | head -n 1)"
    [ "$proxy_is_active" ] && compose_files=$APP_COMPOSE_FILES

    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $compose_files stop
    printf "\nAll running applications stopped.\n"
    printf "\nPress Enter to continue..."; read -r input
}

stop_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    result="$($CONTAINER_ALIAS stop -t 6 "$1" 2>&1)"
    if [ "$result" = "$1" ]; then
        printf "Stopping application ${RED}$1${NC}\n"
    else
        printf "Failed to stop application ${RED}$1${NC}\n$result\n"
    fi
}

restart_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    result="$($CONTAINER_ALIAS restart "$1" 2>&1)"
    if [ "$result" = "$1" ]; then
        printf "Application ${RED}$1${NC} restarted successfully.\n"
    else
        printf "Failed to restart application ${RED}$1${NC}\n$result\n"
    fi
}

remove_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    printf "Stopping and removing applications and volumes...\n\n"
    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES down -v
    echo

    proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=$IGM_PROXY_PROJECT_LABEL" | head -n 1)"
    [ "$proxy_is_active" ] && $WATCHTOWER deploy

    $CONTAINER_ALIAS container prune -f --filter "label=$IGM_PROJECT_LABEL"
    printf "\nAll installed applications and volumes removed.\n"
    printf "\nPress Enter to continue..."; read -r input
}

remove_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    result="$($CONTAINER_ALIAS rm -f -v "$1" 2>&1)"
    if [ "$result" = "$1" ]; then
        printf "Removing application ${RED}$1${NC}\n"
    else
        printf "Failed to remove application ${RED}$1${NC}\n$result\n"
    fi
}

show_application_log() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    clear
    logs_48h=$($CONTAINER_ALIAS logs --since 48h "$1" 2>&1)
    if [ -n "$logs_48h" ]; then
        printf "%s\n" "$logs_48h"
    else
        $CONTAINER_ALIAS logs "$1"
    fi
    printf "\nPress Enter to continue..."; read -r _
}

igm_cleanup() {
    clean_all=false
    cli_mode=false

    for arg in "$@"; do
        case "$arg" in
            --all|all) clean_all=true ;;
            --cli) cli_mode=true ;;
        esac
    done

    printf "Cleaning up IGM resources...\n\n"
    if [ "$cli_mode" = true ]; then        
        if [ "$clean_all" = true ]; then
            printf "${RED}Mode: ${YELLOW}Deep cleanup\n  - Remove stopped applications and images${NC}\n\n"
        else
            printf "${RED}Mode: ${YELLOW}Light cleanup\n  - Remove stopped applications, keep images${NC}\n\n"
        fi
    fi

    # Remove stopped containers
    if [ "$clean_all" = true ]; then
        printf "${BLUE}[1/4] Removing stopped/orphaned applications${NC}\n"
    else
        printf "${BLUE}[1/3] Removing stopped/orphaned applications${NC}\n"
    fi
    $CONTAINER_ALIAS container prune -f --filter "label=$IGM_PROJECT_LABEL"
    printf "\n"

    # Remove unused images (if --all flag)
    if [ "$clean_all" = true ]; then
        printf "${BLUE}[2/4] Removing unused application images${NC}\n"

        # Extract, strip variables, deduplicate
        igm_images=$(awk '/^[[:space:]]*image:/ {img=$2; gsub(/\$\{[^}]*\}/,"",img); if(img!="" && !seen[img]++) print img}' "$COMPOSE_DIR"/*.yml 2>/dev/null)

        # Collect all IGM image IDs (batch operation)
        if [ -n "$igm_images" ]; then
            all_img_ids=""
            for img in $igm_images; do
                img_ids=$($CONTAINER_ALIAS images -q "$img" 2>/dev/null || true)
                all_img_ids="$all_img_ids $img_ids"
            done
            # Remove all collected image IDs in one call
            if [ -n "$all_img_ids" ]; then
                $CONTAINER_ALIAS rmi $all_img_ids 2>/dev/null || true
            fi
        fi
        printf "\n"
    fi

    # Remove unused volumes
    if [ "$clean_all" = true ]; then
        printf "${BLUE}[3/4] Removing unused volumes${NC}\n"
    else
        printf "${BLUE}[2/3] Removing unused volumes${NC}\n"
    fi
    $CONTAINER_ALIAS volume prune -f --filter "label=$IGM_PROJECT_LABEL"
    printf "\n"

    # Remove unused networks
    if [ "$clean_all" = true ]; then
        printf "${BLUE}[4/4] Removing unused networks${NC}\n"
    else
        printf "${BLUE}[3/3] Removing unused networks${NC}\n"
    fi
    $CONTAINER_ALIAS network prune -f --filter "label=$IGM_PROJECT_LABEL"

    printf "\n${GREEN}Cleanup completed.${NC}\n"
    printf "\nPress Enter to continue..."; read -r _
}

show_applications() {
    display_banner --noline

    if [ -z "$HAS_CONTAINER_RUNTIME" ]; then
        echo
        print_no_runtime
        return
    fi

    local proxy_number="${2:-}"
    local proxy_project="com.docker.compose.project=${1}-app-${proxy_number}"

    has_apps() {
        if [ ! -z "$proxy_number" ]; then
            $CONTAINER_ALIAS ps -a -q -f "label=${proxy_project}" | head -n 1
        else
            $CONTAINER_ALIAS ps -a -q -f "label=project=${1}" | head -n 1
        fi
    }
    show_apps() {
        container_type="$1"
        should_group="$2"

        case "$container_type" in
            proxy*) app_type_name="Proxy" ;;
            *) app_type_name="Standard" ;;
        esac

        print_table_output() {
            table="$1"
            app_type_name="$2"
            index="$3"

            count=$(printf '%s\n' "$table" | awk 'NR>1 {c++} END{print c+0}')
            if [ "$index" ]; then
                printf "\n${GREEN}[ ${YELLOW}%s Applications ${NC}| ${RED}%s ${GREEN}]${NC} (%s containers)\n\n" "$app_type_name" "$index" "$count"
            else
                printf "\n${GREEN}[ ${YELLOW}%s Applications ${GREEN}]${NC} (%s containers)\n\n" "$app_type_name" "$count"
            fi
            # Cleanup output
            printf '%s\n' "$table" | sed 's/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*://g; s/\[::\]://g; s/\([0-9][0-9]*\)->[0-9][0-9]*/\1/g'
        }

        if [ "$should_group" = "group" ]; then
            # Find all unique app labels
            set_list=$(
                $CONTAINER_ALIAS ps -a --format '{{.Label "com.docker.compose.project"}}' \
                | grep "^${container_type}-app-[0-9][0-9]*$" \
                | sort -u
            )

            i=1
            for s in $set_list; do
                # Capture table for this set
                table=$(
                    $CONTAINER_ALIAS ps -a -f "label=com.docker.compose.project=$s" \
                    --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}"
                )

                # Skip if table empty (header only)
                line_count=$(printf '%s\n' "$table" | awk 'NF{n++} END{print n+0}')
                if [ "$line_count" -le 1 ]; then
                    i=$((i + 1))
                    continue
                fi

                print_table_output "$table" "$app_type_name" "$i"
                i=$((i+1))
            done
        else
            if [ -n "$proxy_number" ]; then
                filter_label="label=com.docker.compose.project=${container_type}-app-${proxy_number}"
            else
                filter_label="label=project=${container_type}"
            fi
            table=$(
                $CONTAINER_ALIAS ps -a -f "$filter_label" \
                --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}"
            )

            # Skip if no containers
            line_count=$(printf '%s\n' "$table" | awk 'NF{n++} END{print n+0}')
            if [ "$line_count" -le 1 ]; then
                return
            fi

            print_table_output "$table" "$app_type_name"
        fi
    }

    case "$1" in
        ""|"group")
            if [ -z "$(has_apps standard)" ] && [ -z "$(has_apps proxy)" ]; then
                printf "\nNo applications installed.\n"
            else
                if [ -n "$(has_apps standard)" ]; then
                    show_apps standard
                fi
                if [ -n "$(has_apps proxy)" ]; then
                    if [ "$1" = "group" ]; then
                        show_apps proxy group
                    else
                        show_apps proxy
                    fi
                fi
            fi
            ;;
        proxy)
            if [ -z "$(has_apps proxy)" ]; then
                if [ "$proxy_number" = "group" ]; then
                    show_apps proxy group
                elif [ -n "$proxy_number" ]; then
                    printf "\nNo proxy set ${RED}%s${NC} applications installed.\n" "$proxy_number"
                else
                    printf "\nNo proxy applications installed.\n"
                fi
            else
                show_apps proxy
            fi
            ;;
        app)
            if [ -z "$(has_apps standard)" ]; then
                printf "\nNo applications installed.\n"
            else
                show_apps standard
            fi
            ;;
        *)
            printf "\nigm: '$1' is not a valid command. See 'igm help'.\n"
            ;;
    esac
    printf "\nPress Enter to continue..."; read -r _
}

install_single_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    app_data=$(extract_all_app_data ".service_enabled != null" ".is_enabled != null")
    total_apps=$(($TOTAL_APPS + $TOTAL_SERVICES))

    while :; do
        display_banner
        printf "Select an application to install.\n\n"
        display_app_table "$app_data" "install"
        printf "\nEnter number to install (0 to cancel): "; read -r user_input

        if [ -z "$user_input" ] || [ "$user_input" = "0" ]; then
            return
        fi

        if ! [ "$user_input" -ge 1 ] 2>/dev/null || ! [ "$user_input" -le "$total_apps" ] 2>/dev/null; then
            printf "\nInvalid input. Enter number between 1 and $total_apps.\n\nPress enter to continue... "; read -r _
            continue
        fi

        # Find the selected app
        selected_app=$(printf '%s\n' "$app_data" | awk -v n="$user_input" 'BEGIN { c = 1 }
        {
            if ($3 == "true") { if (c == n) { print $1":app"; exit }; c++ }
            if ($2 == "true") { if (c == n) { print $1":service"; exit }; c++ }
        }')
        app_name=${selected_app%:*}
        app_type=${selected_app##*:}

        # Validate credentials
        if ! validate_app_credentials "$app_name" > /dev/null; then
            if sh scripts/app-config.sh --config "$app_name"; then
                display_banner
                unfilled_fields=$(validate_app_credentials "$app_name" --list)
                if [ -n "$unfilled_fields" ]; then
                    printf "${RED}Ensure all fields are filled in and try again.${NC}\n"
                    printf "${RED}Required fields still missing:${NC}\n\n"
                    for field in $unfilled_fields; do
                        printf "  ${YELLOW}- $field${NC}\n"
                    done
                    printf "\nUnable to proceed with installation.\n"
                    printf "\nPress Enter to continue..."; read -r _
                    continue
                fi
            fi
            display_banner --noline
        fi

        type_display="App"
        [ "$app_type" = "service" ] && type_display="Service"

        printf "\n${GREEN}Ready to install:${NC}\n"
        printf "  ${YELLOW}$app_name${NC} ($type_display)\n"
        printf "\nProceed with installation? (Y/N): "; read -r user_input

        case "$user_input" in
            [Yy]*)
                display_banner
                printf "${GREEN}Installing $app_name ($type_display)...${NC}\n\n"

                selected_app=$(printf '%s' "$app_name" | tr 'A-Z' 'a-z')
                [ "$app_type" = "service" ] && selected_app="${selected_app}-pot"

                $CONTAINER_COMPOSE $SYSTEM_ENV_FILES --env-file "$ENV_FILE" $ALL_COMPOSE_FILES up -d "$selected_app"

                if [ $? -eq 0 ]; then
                    printf "\n${GREEN}✓ $app_name installed successfully!${NC}\n"
                    printf "\nInstall another application? (Y/N): "; read -r user_input
                    case "$user_input" in
                        [Yy]*) continue ;;
                        *) break ;;
                    esac
                else
                    printf "\n${RED}✗ Installation failed.${NC}\n\nPress Enter to continue..."; read -r _
                    continue
                fi
                ;;
        esac
    done
}
