#!/bin/sh

WATCHTOWER="sh $ROOT_DIR/scripts/container/watchtower.sh"

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

display_install_info() {
    display_banner

    local is_reinstall_state="$1"

    install_type="installed"
    [ "$is_reinstall_state" = "redeploy" ] && install_type="redeployed"

    app_data=$(jq -r '.[] | select(.is_enabled == true or .service_enabled == true) | "\(.name) \(.service_enabled) \(.is_enabled)"' "$JSON_FILE")
    has_apps_services=$(echo "$app_data" | awk '{if ($2 == "true" || $3 == "true") {print "true"; exit}}')

    if [ "$is_reinstall_state" != "redeploy" ]; then
        total_apps="Total Available:\n ${GREEN}Applications: ${RED}$(jq '. | length' "$JSON_FILE")${NC} | \
                ${YELLOW}Services: ${RED}$(jq '[.[] | select(has("service_enabled"))] | length' "$JSON_FILE")${NC}"
        printf "$total_apps\n\n"
    fi

    if [ -z "$has_apps_services" ]; then
        can_install="false"

        if [ "$is_reinstall_state" = "redeploy" ]; then
            printf "No save state to redeploy from.\nInstall normally to save state first.\n"
        else
            printf "No applications/services currently selected to ${install_type}.\n"
        fi
    else
        printf "The following applications will be ${install_type}.\n\n"

        printf "%-4s %-21s %-8s\n" "No." "Name" "Type"
        printf "%-4s %-21s %-8s\n" "---" "--------------------" "--------"

        printf "%s\n" "$app_data" | awk -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v NC="$NC" '
        BEGIN { counter = 1 }
        {
            if ($2 == "true" && $3 == "true") {
                printf "%-4s %s%-21s %s%s\n", counter, GREEN, $1, "App", NC
                counter++
            }
            if ($2 == "true") {
                printf "%-4s %s%-21s %s%s\n", counter, YELLOW, $1, "Service", NC
            } else {
                printf "%-4s %s%-21s %s%s\n", counter, GREEN, $1, "App", NC
            }
            counter++
        }'
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
        app_data=$(jq -r '.[] | select(.is_enabled == true or .service_enabled == true) | "\(.name) \(.service_enabled) \(.is_enabled)"' "$JSON_FILE")
        has_apps_services=$(echo "$app_data" | awk '{if ($2 == "true" || $3 == "true") {print "true"; exit}}')

        total_apps="Total Available:\n ${GREEN}Applications: ${RED}$(jq '. | length' "$JSON_FILE")${NC} | \
                ${YELLOW}Services: ${RED}$(jq '[.[] | select(has("service_enabled"))] | length' "$JSON_FILE")${NC}"
        printf "$total_apps\n\n"

        if [ -z "$has_apps_services" ]; then
            echo "No applications/services currently selected to install."
            can_install="false"
        else
            printf "The following applications will be installed.\n\n"

            printf "%-4s %-21s %-8s\n" "No." "Name" "Type"
            printf "%-4s %-21s %-8s\n" "---" "--------------------" "--------"

            printf "%s\n" "$app_data" | awk -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v NC="$NC" '
            BEGIN { counter = 1 }
            {
                if ($2 == "true" && $3 == "true") {
                    printf "%-4s %s%-21s %s%s\n", counter, GREEN, $1, "App", NC
                    counter++
                }
                if ($2 == "true") {
                    printf "%-4s %s%-21s %s%s\n", counter, YELLOW, $1, "Service", NC
                } else {
                    printf "%-4s %s%-21s %s%s\n", counter, GREEN, $1, "App", NC
                }
                counter++
            }'
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

        printf "$install_type\n\n"
        [ "$is_selective" = false ] && { $APP_SELECTION --backup > /dev/null 2>&1; $APP_SELECTION --default > /dev/null 2>&1; }

        proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=project=proxy" | head -n 1)"
        [ "$proxy_is_active" ] && $WATCHTOWER modify_only

        $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $compose_files pull
        echo
        $CONTAINER_ALIAS container prune -f
        echo
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
                printf "Redeploying last application install state...\n\n"

                proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=project=proxy" | head -n 1)"
                [ "$proxy_is_active" ] && $WATCHTOWER modify_only

                $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $ALL_COMPOSE_FILES pull
                echo
                $CONTAINER_ALIAS container prune -f
                echo
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
    printf "Starting application "
    $CONTAINER_ALIAS start "$1"
}

stop_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Stopping applications...\n\n"

    compose_files=$ALL_COMPOSE_FILES
    proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=project=proxy" | head -n 1)"
    [ "$proxy_is_active" ] && compose_files=$APP_COMPOSE_FILES

    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $compose_files stop
    printf "\nAll running applications stopped.\n"
    printf "\nPress Enter to continue..."; read -r input
}

stop_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Stopping application"
    $CONTAINER_ALIAS stop -t 6 "$1"
}

remove_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    printf "Stopping and removing applications and volumes...\n\n"
    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES down -v
    echo

    proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=project=proxy" | head -n 1)"
    [ "$proxy_is_active" ] && $WATCHTOWER deploy

    $CONTAINER_ALIAS container prune -f
    printf "\nAll installed applications and volumes removed.\n"
    printf "\nPress Enter to continue..."; read -r input
}

remove_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Removing application"
    $CONTAINER_ALIAS rm -f -v "$1"
}

show_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    printf "Installed Containers:\n\n"

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
        if [ ! -z "$proxy_number" ]; then
            $CONTAINER_ALIAS ps -a -f "label=${proxy_project}"
        else
            $CONTAINER_ALIAS ps -a -f "label=project=${1}"
        fi
    }

    case "$1" in
        "")
            if [ -z "$(has_apps standard)" ] && [ -z "$(has_apps proxy)" ]; then
                echo "No installed applications."
            else
                if [ -n "$(has_apps standard)" ]; then
                    printf "${GREEN}[ ${YELLOW}Standard Applications ${GREEN}]${NC}\n\n"
                    show_apps standard
                fi
                if [ -n "$(has_apps proxy)" ]; then
                    printf "\n${GREEN}[ ${YELLOW}Proxy Applications ${GREEN}]${NC}\n\n"
                    show_apps proxy
                fi
            fi
            ;;
        proxy)
            if [ -z "$(has_apps proxy)" ]; then
                if [ -n "$proxy_number" ]; then
                    printf "No installed set ${RED}${proxy_number}${NC} proxy applications.\n"
                else
                    echo "No installed proxy applications."
                fi
            else
                show_apps proxy
            fi
            ;;
        app)
            if [ -z "$(has_apps standard)" ]; then
                echo "No installed applications."
            else
                show_apps standard
            fi
            ;;
        *)
            echo "igm: '$1' is not a valid command. See 'igm help'."
            ;;
    esac
    printf "\nPress Enter to continue..."; read -r input
}
