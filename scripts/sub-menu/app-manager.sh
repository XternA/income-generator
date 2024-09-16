#!/bin/sh

LOADED_ENV_FILES="--env-file $ENV_FILE --env-file $ENV_SYSTEM_FILE --env-file $ENV_DEPLOY_FILE"

COMPOSE="$(pwd)/compose"
ALL_COMPOSE_FILES="
-f $COMPOSE/compose.yml
-f $COMPOSE/compose.unlimited.yml
-f $COMPOSE/compose.hosting.yml
-f $COMPOSE/compose.local.yml
-f $COMPOSE/compose.single.yml
-f $COMPOSE/compose.service.yml
"

install_applications() {
    display_apps_services() {
        app_data=$(jq -r '.[] | select(.is_enabled == true or .service_enabled == true) | "\(.name) \(.service_enabled) \(.is_enabled)"' "$JSON_FILE")
        has_apps_services=$(echo "$app_data" | awk '{if ($2 == "true" || $3 == "true") {print "true"; exit}}')

        total_apps="Total Available:\n ${GREEN}Applications: ${RED}$(jq '. | length' "$JSON_FILE")${NC} | \
                ${YELLOW}Services: ${RED}$(jq '[.[] | select(has("service_enabled"))] | length' "$JSON_FILE")${NC}\n"
        echo $total_apps

        if [ -z "$has_apps_services" ]; then
            echo "No applications/services currently selected to install."
            can_install="false"
        else
            echo "The following applications will be installed.\n"

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

        echo "\nOption:"
        echo "  ${GREEN}a${NC} = ${GREEN}select applications${NC}"
        echo "  ${YELLOW}s${NC} = ${YELLOW}select services${NC}\n"

        if [ "$can_install" = "false" ]; then
            printf "Select an option or press Enter to return: "
        else
            printf "Do you want to proceed? (Y/N): "
        fi
        read input
    }

    is_selective=false

    while true; do
        display_banner
        options="(1-5)"

        if [ "$1" = "quick_menu" ]; then
            echo "How would you like to install?\n"
            exit_option="0. Exit"
        else
            exit_option="0. Return to Main Menu"
        fi

        echo "1. Selective applications"
        echo "2. All applications including residential support"
        echo "3. Only applications with VPS/Hosting support"
        echo "4. All applications with residential but exclude single install count"
        echo "5. Only applications allowing unlimited install count"
        echo "$exit_option"
        echo
        printf "Select an option %s: " "$options"
        read option

        case "$option" in
            1)
                while true; do
                    display_banner

                    display_apps_services
                    case "$input" in
                        [Yy])
                            if [ "$can_install" = "true" ]; then
                                install_type="Installing selective applications..."
                                compose_files=$ALL_COMPOSE_FILES
                                is_selective=true
                                break
                            fi
                            printf "\nInvalid option.\n\nPress Enter to continue..."; read input
                            ;;
                        [Nn] | "")
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
                compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml"
                ;;
            4)
                install_type="Installing all applications, excluding single instances only..."
                compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml -f $COMPOSE/compose.local.yml"
                ;;
            5)
                install_type="Installing only applications with unlimited install count..."
                compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml"
                ;;
            0)
                break
                ;;
            *)
                echo "\nInvalid option. Please select a valid option $options."
                printf "\nPress Enter to continue..."; read input
                ;;
        esac

        # Skip installation if no valid option was chosen
        [ -z "$compose_files" ] && continue

        display_banner
        if [ ! -s "$ENV_FILE" ]; then
            echo "No configuration for applications found. Configure app credentials first."
            echo "Running setup configuration now...\n"
            sleep 0.6
            $APP_CONFIG
            return
        fi

        echo "$install_type\n"
        [ "$is_selective" = false ] && { $APP_SELECTION --backup > /dev/null 2>&1; $APP_SELECTION --default > /dev/null 2>&1; }
        docker compose $LOADED_ENV_FILES --profile ENABLED $compose_files pull
        echo
        docker container prune -f
        echo
        docker compose $LOADED_ENV_FILES --profile ENABLED $compose_files up --force-recreate --build -d
        [ "$is_selective" = false ] && $APP_SELECTION --restore > /dev/null 2>&1

        printf "\nPress Enter to continue..."; read input
    done
}

start_applications() {
    display_banner
    echo "Starting applications...\n"
    docker compose $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES start
    echo "\nAll installed applications started."
    printf "\nPress Enter to continue..."; read input
}

stop_applications() {
    display_banner
    echo "Stopping applications...\n"
    docker compose $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES stop
    echo "\nAll running applications stopped."
    printf "\nPress Enter to continue..."; read input
}

remove_applications() {
    display_banner
    echo "Stopping and removing applications and volumes...\n"
    docker compose $LOADED_ENV_FILES --profile ENABLED --profile DISABLED $ALL_COMPOSE_FILES down -v
    echo
    docker container prune -f
    echo "\nAll installed applications and volumes removed."
    printf "\nPress Enter to continue..."; read input
}

show_applications() {
    display_banner
    echo "Installed Containers:\n"
    docker compose $LOADED_ENV_FILES $ALL_COMPOSE_FILES ps -a
    printf "\nPress Enter to continue..."; read input
}
