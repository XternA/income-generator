#!/bin/sh

if [ $(uname) = 'Linux' ]; then
    DIR_STR="/data"
    DIR_ESCAPED="\/data"
    SED_INPLACE="sed -i"
elif [ $(uname) = 'Darwin' ]; then
    DIR_STR="/usr/local/data"
    DIR_ESCAPED="\/usr\/local\/data"
    SED_INPLACE="sed -i .bak"
fi

if [ -f "$ENV_SYSTEM_FILE" ]; then
    if grep -q "^DATA_DIR=" "$ENV_SYSTEM_FILE"; then
        $SED_INPLACE "s/^DATA_DIR=.*/DATA_DIR=$DIR_ESCAPED/" "$ENV_SYSTEM_FILE"
    else
        echo "DATA_DIR=$DIR_STR" >> "$ENV_SYSTEM_FILE"
    fi
else
    echo "DATA_DIR=$DIR_STR" >> "$ENV_SYSTEM_FILE"
fi
