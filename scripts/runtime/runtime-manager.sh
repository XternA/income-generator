#!/bin/sh

. scripts/runtime/colima/colima-runtime.sh

_install_runtime() {
    display_banner
    case "$1" in
        --docker)
            sh scripts/$CONTAINER_ALIAS-install.sh
            install_result=$?

            if [ $install_result -eq 0 ]; then
                if [ "$OS_IS_DARWIN" = "false" ] && [ "$OS_IS_ARM" = "true" ]; then
                    newgrp docker <<'EOF'
sh scripts/emulation-layer.sh --add
EOF
                fi
            fi
            ;;
        --colima)
            setup_runtime
            ;;
    esac

    reregister_runtime
    printf "\nPress Enter to continue..."; read -r _
}

_uninstall_runtime() {
    display_banner
    case "$1" in
       --docker) sh scripts/$CONTAINER_ALIAS-uninstall.sh ;;
       --colima) remove_runtime ;;
    esac
    sh scripts/emulation-layer.sh --remove

    reregister_runtime
    printf "\nPress Enter to continue..."; read -r _
}

_setup_runtime() {
    if [ "$OS_IS_DARWIN" = "false" ]; then
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
                ;;
            2)
                _install_runtime --colima
                ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
        esac
    done
}

_remove_runtime() {
    display_banner
    if [ "$OS_IS_DARWIN" = "false" ]; then
        _uninstall_runtime --docker
        return
    fi
    _uninstall_runtime --colima
}

_runtime_cleanup() {
    if [ ! "$HAS_CONTAINER_RUNTIME" ]; then
        display_banner
        print_no_runtime && return
    fi

    while true; do
        display_banner
        printf "About to clean up orphaned applications and downloaded images.\n"
        printf "Running orphaned applications won't be cleaned up unless stopped.\n\n"
        printf "Do you want to perform clean up? (Y/N): "; read -r yn

        case $yn in
            [Yy]*)
                display_banner
                igm_cleanup --all
                break
                ;;
            ""|[Nn]*)
                break ;;
            *)
                printf "\nPlease input yes (Y) or no (N).\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
        esac
    done
}

runtime_menu() {
    case "$1" in
        --cli) exit_option="Exit" ;;
        *) exit_option="Return to Main Menu" ;;
    esac

    while true; do
        display_banner
        _has_colima_runtime && has_colima_runtime=1 || has_colima_runtime=0

        echo "1. Runtime Housekeeping"
        if [ "$has_colima_runtime" -eq 1 ]; then
            options="(1-4)"
            echo "2. Configure Runtime"
            echo "3. Install Runtime"
            echo "4. Uninstall Runtime"
        else
            options="(1-3)"
            echo "2. Install Runtime"
            echo "3. Uninstall Runtime"
        fi
        echo "0. $exit_option"
        printf "\nSelect an option $options: "; read -r option

        case $option in
            0) break ;;
            1) _runtime_cleanup ;;
            2) [ "$has_colima_runtime" -eq 1 ] && configure_runtime || _setup_runtime ;;
            3) [ "$has_colima_runtime" -eq 1 ] && _setup_runtime || _remove_runtime ;;
            4)
                if [ "$has_colima_runtime" -eq 1 ]; then
                    _remove_runtime
                else
                    printf "\nInvalid option. Please select a valid option $options.\n"
                    printf "\nPress Enter to continue..."; read -r _
                fi
                ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
        esac
    done
}