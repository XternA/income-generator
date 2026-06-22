#!/bin/sh

. scripts/installer/binary-installer.sh
. scripts/core/resources.sh

if [ ! -f "$ENV_SYSTEM_FILE" ]; then
    $SYS_INFO > /dev/null 2>&1
    echo >> "$ENV_SYSTEM_FILE"

    CORE_set_resource_limit "low"
    CORE_calculate_limits "low"
    CORE_persist_limits
    echo >> "$ENV_SYSTEM_FILE"

    . scripts/data-dir.sh
else
    . scripts/data-dir.sh
fi

[ ! -f "$ENV_DEPLOY_FILE" ] && $APP_SELECTION --import
