#!/bin/sh

ENV_FILE="$(pwd)/.env"
LIMIT_TYPE="low"

sh scripts/prerequisite.sh

if [ ! -f $ENV_FILE ]; then
    sh scripts/arch.sh > /dev/null 2>&1
    echo >> $ENV_FILE

    sh scripts/set-limit.sh $LIMIT_TYPE > /dev/null 2>&1
    sh scripts/limits.sh $LIMIT_TYPE > /dev/null 2>&1
    echo >> $ENV_FILE

    sh scripts/data-dir.sh > /dev/null 2>&1
    echo "\n#------------------------------------------------------------------------\n" >> $ENV_FILE
else
    sh scripts/data-dir.sh > /dev/null 2>&1
    sh scripts/cleanup.sh
fi
