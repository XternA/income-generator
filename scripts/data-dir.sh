#!/bin/sh

. scripts/core/common.sh

if [ -n "${IGM_DATA_DIR:-}" ]; then
    DATA_DIR="$IGM_DATA_DIR"
elif [ -n "${DATA_DIR:-}" ]; then
    :
else
    DATA_DIR="$(CORE_read_env "DATA_DIR" "$ENV_SYSTEM_FILE")"
fi

if [ -z "$DATA_DIR" ]; then
    if [ "$OS_IS_DARWIN" = "true" ]; then
        DATA_DIR="$HOME/.data"
    else
        DATA_DIR="/data"
    fi
elif [ "${DATA_DIR#/}" = "$DATA_DIR" ]; then
    printf 'igm: ignoring relative IGM_DATA_DIR (%s) — using the default\n' "$DATA_DIR" >&2
    if [ "$OS_IS_DARWIN" = "true" ]; then
        DATA_DIR="$HOME/.data"
    else
        DATA_DIR="/data"
    fi
fi

DATA_DIR="${DATA_DIR%/}"
[ -n "$DATA_DIR" ] || DATA_DIR="/"

CORE_upsert_env "DATA_DIR" "$DATA_DIR" "$ENV_SYSTEM_FILE"
