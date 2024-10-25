#!/bin/sh

DEFAULT_RESOURCE_LIMIT="min"

[ ! -f "$ENV_SYSTEM_FILE" ] && echo "RESOURCE_LIMIT=$DEFAULT_RESOURCE_LIMIT" > "$ENV_SYSTEM_FILE"

if [ $# -eq 0 ]; then
    if grep -q "^RESOURCE_LIMIT=" "$ENV_SYSTEM_FILE"; then
        CURRENT_LIMIT=$(grep "^RESOURCE_LIMIT=" "$ENV_SYSTEM_FILE" | cut -d '=' -f2)
        echo "Current resource limit is set to: $CURRENT_LIMIT"
    else
        echo "RESOURCE_LIMIT=$DEFAULT_RESOURCE_LIMIT" >> "$ENV_SYSTEM_FILE"
        echo "Default resource limit '$DEFAULT_RESOURCE_LIMIT' inserted into $ENV_SYSTEM_FILE"
    fi
    exit 0
fi

ALLOWED_VALUES="base min low mid max"
if ! echo "$ALLOWED_VALUES" | grep -qw "$1"; then
    echo "Invalid argument. Use 'base', 'min', 'low', 'mid', or 'max'."
    exit 1
fi

NEW_LIMIT=$1
if grep -q "^RESOURCE_LIMIT=" "$ENV_SYSTEM_FILE"; then
    $SED_INPLACE "s/^RESOURCE_LIMIT=.*/RESOURCE_LIMIT=$NEW_LIMIT/" "$ENV_SYSTEM_FILE"
else
    echo "RESOURCE_LIMIT=$NEW_LIMIT" >> "$ENV_SYSTEM_FILE"
fi
echo "New resource limit set to: $(echo $NEW_LIMIT | tr '[:lower:]' '[:upper:]')"
