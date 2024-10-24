#!/bin/sh

LIMIT_TYPE="low"

sh scripts/prerequisite.sh

if [ ! -f "$ENV_SYSTEM_FILE" ]; then
    $SYS_INFO > /dev/null 2>&1
    echo >> "$ENV_SYSTEM_FILE"

    sh scripts/set-limit.sh "$LIMIT_TYPE" > /dev/null 2>&1
    sh scripts/limits.sh "$LIMIT_TYPE" > /dev/null 2>&1
    echo >> "$ENV_SYSTEM_FILE"

    sh scripts/data-dir.sh > /dev/null 2>&1
else
    sh scripts/data-dir.sh > /dev/null 2>&1
fi

[ ! -f "$ENV_DEPLOY_FILE" ] && $APP_SELECTION --import
