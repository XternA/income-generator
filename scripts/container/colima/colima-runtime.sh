#!/bin/sh

_autostart="sh scripts/container/colima/colima-autostart.sh"
_brew_path="$(command -v brew | sed 's:/[^/]*$::')"

_has_runtime() {
    [ -f "$_brew_path/colima" ]
}

setup_runtime() {
    if _has_runtime; then
        printf "Colima runtime already installed.\n"
        return
    fi

    printf "Installing Colima Runtime..."
    brew install --formula colima docker docker-compose > /dev/null 2>&1

    display_banner
    config_msg="Configuring Colima...\n\n"
    printf "$config_msg"
    printf "Do you want to configure Colima runtime or use default settings? (Y/N): "; read -r input

    CPU=1
    RAM=2
    DISK=10

    case "$input" in
        [Yy]*)
            while "true"; do
                display_banner
                printf "$config_msg"

                printf "How many CPU cores should be assigned: "; read -r input
                case "$input" in
                    ''|*[!0-9]*) echo "Invalid input. Select from 1 to 4." ;;
                    0) echo "Must be greater than zero." ;;
                    *) CPU=$input; break ;;
                esac
            done

            while "true"; do
                display_banner
                printf "$config_msg"

                printf "How much RAM (in GB) should be assigned: "; read -r input
                case "$input" in
                    ''|*[!0-9]*) echo "Invalid input. Select from 1 to 4." ;;
                    0) echo "Must be greater than zero." ;;
                    *) RAM=$input; break ;;
                esac
            done

            while "true"; do
                display_banner
                printf "$config_msg"

                printf "How much Disk space (in GB) should be assigned: "; read -r input
                case "$input" in
                    ''|*[!0-9]*) echo "Invalid input. Select from 1 to 4." ;;
                    0) echo "Must be greater than zero." ;;
                    *) DISK=$input; break ;;
                esac
            done

            display_banner
            printf "$config_msg"
            ;;
        *|[Nn]*)
            display_banner
            printf "$config_msg"
            ;;
    esac

    printf "Using the following Colima configuration:\n\n"
    printf "CPU (Cores):  ${RED}$CPU${NC}\n"
    printf "RAM (GB):     ${RED}$RAM${NC}\n"
    printf "Disk (GB):    ${RED}$DISK${NC}\n\n"
    colima start --cpu $CPU --memory $RAM --disk $DISK --dns 1.1.1.1 --dns 8.8.8.8
    $_autostart --install $_brew_path
}

remove_runtime() {
    if ! _has_runtime; then
        printf "Colima runtime not installed.\n"
        return
    fi

    printf "Uninstalling Colima Runtime...\n\n"
    colima stop
    colima prune -f -a > /dev/null 2>&1
    yes | colima delete > /dev/null 2>&1
    echo
    brew remove --formula colima docker docker-compose
    brew cleanup --prune=all > /dev/null 2>&1
    $_autostart --remove $_brew_path
}