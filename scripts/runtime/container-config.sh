#!/bin/sh

[ -n "$__CONTAINER_CONFIG_CACHED" ] && return
__CONTAINER_CONFIG_CACHED=1

print_no_runtime() {
    printf "No $CONTAINER_ALIAS runtime installed.\nPlease install runtime engine from tool menu.\n"
    printf "\nPress Enter to continue..."; read -r _
}

_register_compose() {
    if $CONTAINER_ALIAS compose version > /dev/null 2>&1; then
        export CONTAINER_COMPOSE="$CONTAINER_ALIAS compose"
    else
        export CONTAINER_COMPOSE="$CONTAINER_ALIAS-compose"
    fi
}

register_runtime() {
    export CONTAINER_ALIAS="docker"
    export HAS_CONTAINER_RUNTIME="$(command -v $CONTAINER_ALIAS 2>/dev/null)"
    _register_compose
}

reregister_runtime() {
    hash -r
    unset HAS_CONTAINER_RUNTIME
    unset CONTAINER_COMPOSE
    unset CONTAINER_ALIAS
    register_runtime
}

# Init sourcing --------
register_runtime
