#!/bin/sh

_autostart="sh scripts/runtime/colima/colima-autostart.sh"
_brew_path="$(command -v brew | sed 's:/[^/]*$::')"

DEFAULT_CPU=1
DEFAULT_MEMORY=2
DEFAULT_DISK=10

_has_colima_runtime() {
    [ -f "$_brew_path/colima" ]
}

_colima() {
    set -- "$@"
    if [ "$IS_ARM_ARCH" = "false" ]; then
        colima start --cpu "$1" --memory "$2" --disk "$3" --vm-type=qemu
    else
        colima start --cpu "$1" --memory "$2" --disk "$3" --vm-type=vz --vz-rosetta
    fi
}

_display_colima_stats() {
    display_msg="${1:-Current Colima configuration:}"
    c_cpu="${2:-$DEFAULT_CPU}"
    c_memory="${3:-$DEFAULT_MEMORY}"
    c_disk="${4:-$DEFAULT_DISK}"
    driver="$5"

    printf "$display_msg\n\n"
    if [ "$driver" ]; then
        printf "Driver:        ${GREEN}$driver${NC}\n"
    fi
    printf "CPU  (Cores):  ${RED}$c_cpu${NC}\n"
    printf "RAM  (GB):     ${RED}$c_memory${NC}\n"
    printf "Disk (GB):     ${RED}$c_disk${NC}\n\n"
}

_show_current_colima_setup() {
    set -- $(colima status --json | jq -r '.cpu, (.memory / 1e9 | floor), (.disk / 1e9 | floor), .driver')
    case "$4" in
        QEMU) driver="QEMU" ;;
        *) driver="Native" ;;
    esac
    _display_colima_stats "" "$1" "$2" "$3" "$driver"
}

_run_config_prompt() {
    config_msg="$1"

    cpu_cores=$(sysctl -n hw.physicalcpu)
    total_ram=$(($(sysctl -n hw.memsize) / 1000000000))
    free_disk=$(df -k / | awk 'NR==2 { print int($4 * 1024 / 1000000000) }')

    cpu_allowed=$((cpu_cores * 75 / 100))
    ram_allowed=$((total_ram * 75 / 100))
    disk_allowed=$((free_disk * 75 / 100))

    while :; do
        display_banner
        printf "$config_msg"
        printf "System CPU Cores: ${YELLOW}$cpu_cores${NC}\nAllowed Cores:    ${GREEN}$cpu_allowed${NC}\n\n"

        printf "How many CPU cores should be assigned: "; read -r cpu
        [ -z "$cpu" ] && cpu=1 && break

        if printf '%s' "$cpu" | grep -Eq '^[0-9]+$'; then
            if [ "$cpu" -ge 1 ] && [ "$cpu" -le "$cpu_allowed" ]; then
                break
            fi
        fi

        printf "\nInvalid input. Enter a number between 1 and %s.\n" "$cpu_allowed"
        printf "\nPress Enter to continue..."; read -r _
    done

    while :; do
        display_banner
        printf "$config_msg"
        printf "System RAM:  ${YELLOW}$total_ram${NC} GB\nAllowed RAM: ${GREEN}$ram_allowed${NC} GB\n\n"

        printf "How much RAM (in GB) should be assigned: "; read -r memory
        [ -z "$memory" ] && memory=2 && break

        if printf '%s' "$memory" | grep -Eq '^[0-9]+$'; then
            if [ "$memory" -ge 1 ] && [ "$memory" -le "$ram_allowed" ]; then
                break
            fi
        fi

        printf "\nInvalid input. Enter a number between 1 and %s.\n" "$ram_allowed"
        printf "\nPress Enter to continue..."; read -r _
    done

    while :; do
        display_banner
        printf "$config_msg"
        printf "Free Disk Space: ${YELLOW}$free_disk${NC} GB\nAllowed Space:   ${GREEN}$disk_allowed${NC} GB\n\n"

        printf "How much disk space (in GB) should be assigned: "; read -r disk
        [ -z "$disk" ] && disk=10 && break

        if printf '%s' "$disk" | grep -Eq '^[0-9]+$'; then
            if [ "$disk" -ge 10 ] && [ "$disk" -le "$disk_allowed" ]; then
                break
            fi
        fi

        printf "\nInvalid input. Enter a number between 10 and %s.\n" "$disk_allowed"
        printf "\nPress Enter to continue..."; read -r _
    done
}

configure_runtime() {
    while :; do
        display_banner
        _show_current_colima_setup

        printf "Do you want to configure a new setting? (Y/N): "; read -r yn
        case "$yn" in
            [Yy]*)
                _run_config_prompt "Configuring new Colima setting...\n\n"
                set -- "$cpu" "$memory" "$disk"

                display_banner
                _display_colima_stats "Applying new Colima configuration..." "$1" "$2" "$3"

                colima stop -f
                sleep 1.5
                _colima "$1" "$2" "$3"

                printf "\nColima updated with the new applied configuration.\n"
                printf "\nPress Enter to continue..."; read -r _
                break
                ;;
            ""|[Nn]*) break ;;
            *)
                printf "\nInvalid option. Please select yes (Y) or no (N).\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
        esac
    done
}

setup_runtime() {
    if _has_colima_runtime; then
        printf "Colima runtime already installed.\n"
        return
    fi

    printf "Installing Colima Runtime..."
    brew install --formula colima docker docker-compose > /dev/null 2>&1

    display_banner
    config_msg="Configuring Colima...\n\n"
    printf "$config_msg"
    printf "Do you want to configure Colima runtime or use default settings? (Y/N): "; read -r input

    case "$input" in
        [Yy]*)
            _run_config_prompt "$config_msg"
            set -- "$cpu" "$memory" "$disk"
            
            display_banner
            printf "$config_msg"

            _display_colima_stats "Using the following Colima configuration:" "$1" "$2" "$3"
            _colima "$1" "$2" "$3"
            ;;
        *|[Nn]*)
            display_banner
            printf "$config_msg"

            _display_colima_stats "Using default Colima configuration:"
            _colima "$DEFAULT_CPU" "$DEFAULT_MEMORY" "$DEFAULT_DISK"
            ;;
    esac
    $_autostart --install $_brew_path
}

remove_runtime() {
    if ! _has_colima_runtime; then
        printf "Runtime not installed.\n"
        return
    fi

    printf "Uninstalling Colima Runtime...\n\n"
    colima stop -f
    colima prune -f -a > /dev/null 2>&1
    colima delete -f
    rm -rf -- "$HOME/.colima"
    echo
    brew remove --formula colima docker docker-compose
    brew cleanup --prune=all > /dev/null 2>&1
    $_autostart --remove $_brew_path
}