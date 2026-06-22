#!/bin/sh

. scripts/shared-component.sh
. scripts/core/resources.sh

[ ! -f "$ENV_SYSTEM_FILE" ] && echo "RESOURCE_LIMIT=min" > "$ENV_SYSTEM_FILE"

if [ $# -eq 0 ]; then
    CORE_read_resource_limit
    if [ -n "$(CORE_read_env "RESOURCE_LIMIT" "$ENV_SYSTEM_FILE")" ]; then
        echo "Current resource limit is set to: $CORE_RESOURCE_LIMIT"
    else
        CORE_upsert_env "RESOURCE_LIMIT" "min" "$ENV_SYSTEM_FILE"
        echo "Default resource limit 'min' inserted into $ENV_SYSTEM_FILE"
    fi
    exit 0
fi

if ! CORE_set_resource_limit "$1"; then
    echo "Invalid argument. Use 'base', 'min', 'low', 'mid', or 'max'."
    exit 1
fi
CORE_calculate_limits "$1"
CORE_persist_limits
CORE_apply_limits
echo "New resource limit set to: $(echo $1 | tr '[:lower:]' '[:upper:]')"
