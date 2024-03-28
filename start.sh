#!/bin/sh

sh scripts/init.sh

ARCH="$(sh scripts/arch.sh)"
STATS="$(sh scripts/limits.sh "$(sh scripts/set-limit.sh | awk '{print $NF}')")"
ENV_FILE="$(pwd)/.env"
COMPOSE="$(pwd)/compose"
ALL_COMPOSE_FILES="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml -f $COMPOSE/compose.local.yml -f $COMPOSE/compose.single.yml"

PINK='\033[1;35m'
NC='\033[0m'

display_banner() {
    clear
    echo "Income Generator Application Manager"
    echo "----------------------------------------"
    echo
}

stats() {
    printf "%s\n" "$ARCH"
    echo
    printf "%s\n" "$STATS"
    echo "----------------------------------------"
    echo
}

option_1() {
    while true; do
        display_banner
        options="(1-4)"

        echo "1. Only applications with VPS/Hosting support"
        echo "2. All applications including residential IPs only support"
        echo "3. All applications including residential IPs only support, excluding single instances only"
        echo "4. Applications with unlimited counts"
        echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1|2|3|4)
                compose_files=""
                install_type="\n"
                case $option in
                    1)
                        install_type="Installing only applications supporting VPS/Hosting..."
                        compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml"
                        ;;
                    2)
                        install_type="Installing all application..."
                        compose_files=$ALL_COMPOSE_FILES
                        ;;
                    3)
                        install_type="Installing all applications, excluding single instances only..."
                        compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml -f $COMPOSE/compose.hosting.yml -f $COMPOSE/compose.local.yml"
                        ;;
                    4)
                        install_type="Installing only applications with unlimited install count..."
                        compose_files="-f $COMPOSE/compose.yml -f $COMPOSE/compose.unlimited.yml"
                        ;;
                    esac
                    display_banner
                    echo $install_type
                    echo
                    docker compose --env-file $ENV_FILE $compose_files pull
                    docker container prune -f
                    docker compose --env-file $ENV_FILE $compose_files up --force-recreate --build -d
                    ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo
                echo "Invalid option. Please select a valid option $options."
                ;;
        esac
        printf "\nPress Enter to continue..."; read input
    done
}

option_2() {
    display_banner
    echo "Setting up configurations..."
    sh scripts/config.sh
    echo
    printf "Press Enter to continue..."; read input
}

option_3() {
    display_banner
    echo "Starting applications..."
    echo
    docker compose --env-file $ENV_FILE $ALL_COMPOSE_FILES start
    echo
    echo "All installed applications started."
    echo
    printf "Press Enter to continue..."; read input
}

option_4() {
    display_banner
    echo "Stopping applications..."
    echo
    docker compose --env-file $ENV_FILE $ALL_COMPOSE_FILES stop
    echo
    echo "All running applications stopped."
    echo
    printf "Press Enter to continue..."; read input
}

option_5() {
    display_banner
    echo "Stopping and removing applications and volumes..."
    echo
    docker container prune -f
    docker compose --env-file $ENV_FILE $ALL_COMPOSE_FILES stop
    docker compose --env-file $ENV_FILE $ALL_COMPOSE_FILES down -v
    echo
    echo "All installed applications and volumes removed."
    echo
    printf "Press Enter to continue..."; read input
}

option_6() {
    display_banner
    echo "Installed Containers:"
    echo
    docker compose --env-file $ENV_FILE $ALL_COMPOSE_FILES ps -a
    echo
    printf "Press Enter to continue..."; read input
}

option_7() {
    while true; do
        display_banner
        options="(1-2)"

        echo "1. Install Docker"
        echo "2. Uninstall Docker"
        echo "0. Back to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1)
                display_banner
                echo "Installing Docker..."
                echo
                sh scripts/docker-install.sh
                ;;
            2)
                display_banner
                echo "Uninstalling Docker..."
                echo
                sh scripts/docker-uninstall.sh
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo
                echo "Invalid option. Please select a valid option $options."
                ;;
        esac
        printf "\nPress Enter to continue..."; read input
    done
}

option_8() {
    while true; do
        display_banner
        options="(1-5)"

        echo "Pick a new resource limit utilization based on current hardware limits."
        echo
        printf "%s\n" "$STATS"
        echo
        echo "1. BASE   -->   320MB RAM"
        echo "2. MIN    -->   12.5% Total RAM"
        echo "3. LOW    -->   18.75% Total RAM"
        echo "4. MID    -->   25% Total RAM"
        echo "5. MAX    -->   50% Total RAM"
        echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1|2|3|4|5)
                limit_type=""
                case $option in
                    1) limit_type="base" ;;
                    2) limit_type="min" ;;
                    3) limit_type="low" ;;
                    4) limit_type="mid" ;;
                    5) limit_type="max" ;;
                esac
                echo
                sh scripts/set-limit.sh "$limit_type"
                STATS="$(sh scripts/limits.sh "$(sh scripts/set-limit.sh | awk '{print $NF}')")"
                sh scripts/cleanup.sh
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo
                echo "Invalid option. Please select a valid option $options."
                ;;
        esac
        printf "\nPress Enter to continue..."; read input
    done
}

option_9() {
    while true; do
        display_banner

        options="(1-3)"

        echo "1. Reset resource limit only"
        echo "2. Reset all back to default"
        echo "3. Check and get update"
        echo "0. Return to Main Menu"
        echo
        read -p "Select an option $options: " option

        case $option in
            1)
                echo
                sh scripts/set-limit.sh low
                STATS="$(sh scripts/limits.sh "$(sh scripts/set-limit.sh | awk '{print $NF}')")"
                sh scripts/cleanup.sh
                ;;
            2)
                rm -rf .env; sh scripts/init.sh > /dev/null 2>&1
                echo
                echo "All settings have been reset. Please run ${PINK}Setup Configuration${NC} again."
                ;;
            3)
                echo
                echo "Checking and attempting to get latest updates...\n"
                git fetch; git reset --hard; git pull
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                echo
                echo "Invalid option. Please select a valid option $options."
                ;;
        esac
        printf "\nPress Enter to continue..."; read input
    done
}

# Main script
while true; do
    display_banner
    stats

    options="(1-9)"

    echo "1. Install & Run Applications"
    echo "2. Setup Configuration"
    echo "3. Start Applications"
    echo "4. Stop Applications"
    echo "5. Remove Applications"
    echo "6. Show Installed Applications"
    echo "7. Install/Uninstall Docker"
    echo "8. Change Resource Limits"
    echo "9. Update/Reset Config"
    echo "0. Quit"
    echo
    read -p "Select an option $options: " choice

    case $choice in
        0) display_banner; echo "Quitting..."; sleep 0.62; clear; exit 0 ;;
        1) option_1 ;;
        2) option_2 ;;
        3) option_3 ;;
        4) option_4 ;;
        5) option_5 ;;
        6) option_6 ;;
        7) option_7 ;;
        8) option_8 ;;
        9) option_9 ;;
        *) echo "Invalid option. Please select a valid option $options." ;;
    esac
done
