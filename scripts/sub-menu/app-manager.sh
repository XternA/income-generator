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
                ${YELLOW}Services: ${RED}$(jq '[.[] | select(has("service_enabled"))] | length' "$JSON_FILE")${NC}\n"
        echo -e $total_apps
    fi

    if [ -z "$has_apps_services" ]; then
        can_install="false"

        if [ "$is_reinstall_state" = "redeploy" ]; then
            echo -e "No save state to redeploy from.\nInstall normally to save state first."
        else
            echo "No applications/services currently selected to ${install_type}."
        fi
    else
        echo -e "The following applications will be ${install_type}.\n"

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

    if [ "$is_reinstall_state" != "redeploy" ]; then
        echo -e "\nOption:"
        echo -e "  ${GREEN}a${NC} = ${GREEN}select applications${NC}"
        echo -e "  ${YELLOW}s${NC} = ${YELLOW}select services${NC}"
    else
        if [ "$can_install" = "true" ]; then
            echo -e "\nOption:"
            echo -e "  ${RED}c${NC} = ${RED}clear redeploy state${NC}"
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
    read input
}

install_applications() {
    display_apps_services() {
        app_data=$(jq -r '.[] | select(.is_enabled == true or .service_enabled == true) | "\(.name) \(.service_enabled) \(.is_enabled)"' "$JSON_FILE")
        has_apps_services=$(echo "$app_data" | awk '{if ($2 == "true" || $3 == "true") {print "true"; exit}}')

        total_apps="Total Available:\n ${GREEN}Applications: ${RED}$(jq '. | length' "$JSON_FILE")${NC} | \
                ${YELLOW}Services: ${RED}$(jq '[.[] | select(has("service_enabled"))] | length' "$JSON_FILE")${NC}\n"
        echo -e $total_apps

        if [ -z "$has_apps_services" ]; then
            echo "No applications/services currently selected to install."
            can_install="false"
        else
            echo -e "The following applications will be installed.\n"

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

        echo -e "\nOption:"
        echo -e "  ${GREEN}a${NC} = ${GREEN}select applications${NC}"
        echo -e "  ${YELLOW}s${NC} = ${YELLOW}select services${NC}\n"

        if [ "$can_install" = "false" ]; then
            printf "Select an option or press Enter to return: "
        else
            printf "Do you want to proceed? (Y/N): "
        fi
        read input
    }

    while true; do
        display_banner
        [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

        if [ "$1" = "quick_menu" ]; then
            echo -e "How would you like to install?\n"
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
        echo
        printf "Select an option %s: " "$options"
        read option

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
                            printf "\nInvalid option.\n\nPress Enter to continue..."; read input
                            ;;
                        [Nn])
                            if [ "$can_install" = "true" ]; then
                                compose_files=""
                                break
                            fi
                            printf "\nInvalid option.\n\nPress Enter to continue..."; read input
                            ;;
                        a)
                            $APP_SELECTION
                            ;;
                        s)
                            $APP_SELECTION service
                            ;;
                        *)
                            printf "\nInvalid option.\n\nPress Enter to continue..."; read input
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
                echo -e "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac

        # Skip installation if no valid option was chosen
        [ -z "$compose_files" ] && continue

        display_banner
        if [ ! -s "$ENV_FILE" ]; then
            echo "No configuration for applications found. Configure app credentials first."
            echo -e "Running setup configuration now...\n"
            sleep 0.6
            $APP_CONFIG
            return
        fi

        echo -e "$install_type\n"
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

        printf "\nPress Enter to continue..."; read input
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
                echo -e "Redeploying last application install state...\n"

                proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=project=proxy" | head -n 1)"
                [ "$proxy_is_active" ] && $WATCHTOWER modify_only

                $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $ALL_COMPOSE_FILES pull
                echo
                $CONTAINER_ALIAS container prune -f
                echo
                $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED $ALL_COMPOSE_FILES up --force-recreate --build -d
                [ "$proxy_is_active" ] && $WATCHTOWER restore_only

                printf "\nPress Enter to continue..."; read input
                break
                ;;
            [Nn])
                break
                ;;
            c)
                rm -f "$ENV_DEPLOY_FILE.save"
                echo -e "\nRedeploy save state has been cleared."
                printf "\nPress Enter to continue..."; read input
                ;;
            *)
                printf "\nInvalid option.\n\nPress Enter to continue..."; read input
                ;;
        esac
    done
    $APP_SELECTION --restore > /dev/null 2>&1
}

start_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    echo -e "Starting applications...\n"
    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES start
    echo -e "\nAll installed applications started."
    printf "\nPress Enter to continue..."; read input
}

start_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Starting application "
    $CONTAINER_ALIAS start "$1"
}

stop_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    echo -e "Stopping applications...\n"

    compose_files=$ALL_COMPOSE_FILES
    proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=project=proxy" | head -n 1)"
    [ "$proxy_is_active" ] && compose_files=$APP_COMPOSE_FILES

    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $compose_files stop
    echo -e "\nAll running applications stopped."
    printf "\nPress Enter to continue..."; read input
}

stop_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Stopping application "
    $CONTAINER_ALIAS stop -t 6 "$1"
}

remove_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    echo -e "Stopping and removing applications and volumes...\n"
    $CONTAINER_COMPOSE $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES down -v
    echo

    proxy_is_active="$($CONTAINER_ALIAS ps -a -q -f "label=project=proxy" | head -n 1)"
    [ "$proxy_is_active" ] && $WATCHTOWER deploy

    $CONTAINER_ALIAS container prune -f
    echo -e "\nAll installed applications and volumes removed."
    printf "\nPress Enter to continue..."; read input
}

remove_application() {
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return
    printf "Removing application "
    $CONTAINER_ALIAS rm -f -v "$1"
}

show_applications() {
    display_banner
    [ ! "$HAS_CONTAINER_RUNTIME" ] && print_no_runtime && return

    echo -e "Installed Containers:\n"

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
                    echo -e "${GREEN}[ ${YELLOW}Standard Applications ${GREEN}]${NC}\n"
                    show_apps standard
                fi
                if [ -n "$(has_apps proxy)" ]; then
                    echo -e "\n${GREEN}[ ${YELLOW}Proxy Applications ${GREEN}]${NC}\n"
                    show_apps proxy
                fi
            fi
            ;;
        proxy)
            if [ -z "$(has_apps proxy)" ]; then
                if [ -n "$proxy_number" ]; then
                    echo -e "No installed set ${RED}${proxy_number}${NC} proxy applications."
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
    printf "\nPress Enter to continue..."; read input
}
