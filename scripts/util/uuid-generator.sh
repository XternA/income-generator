#!/bin/sh

generate_uuid() {
    if [ "$(uname)" = "Darwin" ]; then
        uuid="$(uuidgen | tr 'A-Z' 'a-z')"
    else
        uuid="$(cat /proc/sys/kernel/random/uuid)"
    fi

    case "$1" in
        1) echo "sdk-node-$(echo "$uuid" | tr -d '-')" ;;
        2) echo "$uuid" ;;
        3) echo "$uuid" | tr -d '-' ;;
    esac
}
