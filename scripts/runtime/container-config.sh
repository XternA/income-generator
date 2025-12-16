#!/bin/sh

print_no_runtime() {
    printf "No $CONTAINER_ALIAS runtime installed.\nPlease install runtime engine from tool menu.\n"
    printf "\nPress Enter to continue..."; read -r input
}

register_compose() {
    if $CONTAINER_ALIAS compose version > /dev/null 2>&1; then
        export CONTAINER_COMPOSE="$CONTAINER_ALIAS compose"
    else
        export CONTAINER_COMPOSE="$CONTAINER_ALIAS-compose"
    fi
}

register_runtime() {
    export CONTAINER_ALIAS="docker"

    if [ -n "$WSL_DISTRO_NAME" ]; then
        export HAS_CONTAINER_RUNTIME="$(where.exe $CONTAINER_ALIAS 2> /dev/null >&1)"
    else
        export HAS_CONTAINER_RUNTIME="$(command -v $CONTAINER_ALIAS 2> /dev/null 1>&1)"
    fi
    register_compose
}

case "$1" in
    --register) register_compose ;;
    *) register_runtime ;;
esac
