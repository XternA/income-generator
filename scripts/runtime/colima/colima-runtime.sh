#!/bin/sh

_autostart="sh scripts/runtime/colima/colima-autostart.sh"
_brew_path="$(command -v brew | sed 's:/[^/]*$::')"

_has_colima_runtime() {
    [ -f "$_brew_path/colima" ]
}

_colima() {
    cpu="${1:-1}"
    memory="${2:-2}"
    disk="${3:-10}"
    extra_args="${4:-}"

    extra_args=("${@:4}")
    [ ${#extra_args[@]} -eq 0 ] && extra_args=(--vm-type=qemu)

    colima start --cpu "$cpu" --memory "$memory" --disk "$disk" --dns 1.1.1.1 --dns 8.8.8.8 "${extra_args[@]}"
}

_display_colima_stats() {
    display_msg="Current Colima configuration:"

    cpu=1
    memory=2
    disk=10

    for arg in "$@"; do
        if [ "$arg" = "--status" ]; then
            set -- $(colima status --json | jq -r '.cpu, (.memory / 1e9 | floor), (.disk / 1e9 | floor), .driver')
            cpu=$1
            memory=$2
            disk=$3
            driver=$([ "$4" = "QEMU" ] && printf "QEMU" || printf "Rosetta")
        else
            display_msg=$arg
        fi
    done

    printf "$display_msg\n\n"
    [ $driver ] && printf "Driver:        ${GREEN}$driver${NC}\n"
    printf "CPU  (Cores):  ${RED}$cpu${NC}\n"
    printf "RAM  (GB):     ${RED}$memory${NC}\n"
    printf "Disk (GB):     ${RED}$disk${NC}\n\n"
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
        _display_colima_stats --status

        options="(1-2)"

        echo "1. Configure Colima"
        echo "2. Change Runtime Driver"
        echo "0. Return to Main Menu"
        printf "\nSelect an option $options: "; read -r option

        case "$option" in
            ""|0) break ;;
            1)
                while :; do
                    display_banner
                    _display_colima_stats
                    printf "Do you want to configure a new setting? (Y/N): "; read -r yn
                    case "$yn" in
                        [Yy]*)
                            _run_config_prompt "Configuring new Colima setting...\n\n"

                            display_banner
                            _display_colima_stats "Applying new Colima configuration..."

                            colima stop
                            sleep 1.5
                            _colima "$cpu" "$memory" "$disk"

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
                ;;
            2)
                while :; do
                    display_banner
                    printf "Current Driver: ${GREEN}$driver${NC}\n\n"
                    printf "Changing runtime driver requires deleting the current Colima instance.\n"
                    printf "All applications will need to be reinstalled after the change.\n\n"

                    driver_type=$( [ "$driver" = "QEMU" ] && printf "Rosetta" || printf "QEMU" )
                    printf "Do you want to change Colima runtime driver to ${YELLOW}$driver_type${NC}? (Y/N): "; read -r yn

                    case "$yn" in
                        ""|[Nn]*) break ;;
                        [Yy])
                            display_banner
                            printf "Changing Colima to use $driver_type runtime driver...\n\n"

                            colima stop -f
                            colima prune -f -a > /dev/null 2>&1
                            colima delete -f
                            sleep 1.5

                            if [ "$driver" == "QEMU" ]; then
                                _colima $cpu "$memory" "$disk" --vm-type=vz --vz-rosetta
                            else
                                _colima $cpu "$memory" "$disk"
                            fi

                            printf "\nRuntime driver changed to ${GREEN}$driver_type${NC}.\n"
                            printf "\nPress Enter to continue..."; read -r _
                            break
                            ;;
                        *)
                            printf "\nInvalid option. Please select yes (Y) or no (N).\n"
                            printf "\nPress Enter to continue..."; read -r _
                            ;;
                    esac
                done
                ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
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

            display_banner
            printf "$config_msg"
            ;;
        *|[Nn]*)
            display_banner
            printf "$config_msg"
            ;;
    esac

    _display_colima_stats "Using the following Colima configuration:"
    _colima "$cpu" "$memory" "$disk"
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
    rm -rf $HOME/.colima
    echo
    brew remove --formula colima docker docker-compose
    brew cleanup --prune=all > /dev/null 2>&1
    $_autostart --remove $_brew_path
}