#!/bin/sh

[ -n "$__UUID_GENERATOR" ] && return
__UUID_GENERATOR=1

generate_uuid() {
    if [ "$OS_IS_DARWIN" = "true" ]; then
        uuid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
    else
        read uuid < /proc/sys/kernel/random/uuid
    fi

    case "$1" in
        1) echo "sdk-node-$(echo "$uuid" | tr -d '-')" ;;
        2) echo "$uuid" ;;
        3) echo "$uuid" | tr -d '-' ;;
    esac
}
