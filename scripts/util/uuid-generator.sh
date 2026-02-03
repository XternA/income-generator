#!/bin/sh

[ -n "$__UUID_GENERATOR" ] && return
__UUID_GENERATOR=1

_output_uuid() {
    case "$1" in
        1) echo "sdk-node-$(echo "$uuid" | tr -d '-')" ;;
        2) echo "$uuid" ;;
        3) echo "$uuid" | tr -d '-' ;;
    esac
}

generate_uuid() {
    if [ "$OS_IS_DARWIN" = "true" ]; then
        uuid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
    else
        read uuid < /proc/sys/kernel/random/uuid
    fi
    _output_uuid "$1"
}

generate_uuid_batch() {
    count="$1"
    uuid_type="$2"

    if [ "$OS_IS_DARWIN" = "true" ]; then
        i=0
        while [ "$i" -lt "$count" ]; do
            uuid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
            _output_uuid "$uuid_type"
            i=$((i + 1))
        done
    else
        i=0
        while [ "$i" -lt "$count" ]; do
            read uuid < /proc/sys/kernel/random/uuid
            _output_uuid "$uuid_type"
            i=$((i + 1))
        done
    fi
}
