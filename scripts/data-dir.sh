#!/bin/sh

. scripts/core/common.sh

if [ "$OS_IS_DARWIN" = "true" ]; then
    DATA_DIR="/usr/local/data"
else
    DATA_DIR="/data"
fi

CORE_upsert_env "DATA_DIR" "$DATA_DIR" "$ENV_SYSTEM_FILE"
