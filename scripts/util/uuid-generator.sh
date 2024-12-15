#!/bin/sh

generate_uuid() {
    if [ "$(uname)" = "Darwin" ]; then
        uuid="$(uuidgen | tr 'A-Z' 'a-z')"
    else
        uuid="$(cat /proc/sys/kernel/random/uuid)"
    fi

    case "$1" in
        "#") echo "sdk-node-$(echo "$uuid" | tr -d '-')" ;;
        "*") echo "$uuid" ;;
        "&") echo "$uuid" | tr -d '-' ;;
    esac
}
