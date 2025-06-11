#!/bin/sh

. scripts/runtime/colima/colima-runtime.sh

_install_runtime() {
    display_banner
    case "$1" in
        --docker) sh scripts/$CONTAINER_ALIAS-install.sh ;;
        --colima) setup_runtime ;;
    esac
    sh scripts/runtime/container-config.sh --register
    sh scripts/emulation-layer.sh --add
}

_uninstall_runtime() {
    display_banner
    case "$1" in
       --docker) sh scripts/$CONTAINER_ALIAS-uninstall.sh ;;
       --colima) remove_runtime ;;
    esac
    sh scripts/emulation-layer.sh --remove
}

_setup_runtime() {
    if [ "$OS" != "darwin" ]; then
        _install_runtime --docker
        return
    fi

    while true; do
        display_banner
        options="(1-2)"

        printf "Choose a runtime engine to install.\n\n"
        echo "1. Docker"
        echo "2. Colima"
        echo "0. Go Back"
        printf "\nSelect an option $options: "; read -r option

        case $option in
            0) break ;;
            1)
                _install_runtime --docker
                printf "\nPress Enter to continue..."; read -r input
                ;;
            2)
                _install_runtime --colima
                printf "\nPress Enter to continue..."; read -r input
                ;;
            *)
                printf "\n\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

_remove_runtime() {
    display_banner
    if [ "$OS" != "darwin" ]; then
        _install_runtime --docker
        return
    fi
    _uninstall_runtime --colima
    printf "\nPress Enter to continue..."; read -r input
}

runtime_menu() {
    while true; do
        display_banner
        options="(1-3)"

        echo "1. Docker Housekeeping"
        echo "2. Install Runtime"
        echo "3. Uninstall Runtime"
        echo "0. Return to Main Menu"
        echo
        printf "Select an option $options: "; read -r option

        case $option in
            1)
                while true; do
                    display_banner
                    printf "About to clean up orphaned applications and downloaded images.\n"
                    printf "Running orphaned applications won't be cleaned up unless stopped.\n\n"
                    printf "Do you want to perform clean up? (Y/N): "; read -r yn

                    case $yn in
                        [Yy]*)
                            display_banner
                            printf "Removing orphaned applications, volumes and downloaded images...\n\n"
                            $CONTAINER_ALIAS system prune -a -f --volumes
                            printf "\nCleanup completed.\n"
                            printf "\nPress Enter to continue..."; read -r input
                            break
                            ;;
                        [Nn]*)
                            break
                            ;;
                        *)
                            printf "\nPlease input yes (Y/y) or no (N/n).\n"
                            printf "\nPress Enter to continue..."; read -r input
                            ;;
                    esac
                done
                ;;
            2)
                _setup_runtime
                ;;
            3)
                _remove_runtime
                ;;
            0)
                break  # Return to the main menu
                ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}