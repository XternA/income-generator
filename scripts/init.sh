#!/bin/sh

ENV_FILE="$(pwd)/.env"
LIMIT_TYPE="low"

sh scripts/pre-requisite.sh

if [ ! -f $ENV_FILE ]; then
    sh scripts/arch.sh > /dev/null 2>&1
    echo >> $ENV_FILE
    sh scripts/set-limit.sh $LIMIT_TYPE
    sh scripts/limits.sh $LIMIT_TYPE
    echo "\n#------------------------------------------------------------------------\n" >> $ENV_FILE
fi

sh scripts/cleanup.sh
