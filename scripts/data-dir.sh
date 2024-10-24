#!/bin/sh

case "$(uname)" in
    Linux)
        DIR_STR="/data"
        DIR_ESCAPED="\/data"
        ;;
    Darwin)
        DIR_STR="/usr/local/data"
        DIR_ESCAPED="\/usr\/local\/data"
        ;;
esac

if [ -f "$ENV_SYSTEM_FILE" ]; then
    if grep -q "^DATA_DIR=" "$ENV_SYSTEM_FILE"; then
        $SED_INPLACE "s/^DATA_DIR=.*/DATA_DIR=$DIR_ESCAPED/" "$ENV_SYSTEM_FILE"
    else
        echo "DATA_DIR=$DIR_STR" >> "$ENV_SYSTEM_FILE"
    fi
else
    echo "DATA_DIR=$DIR_STR" >> "$ENV_SYSTEM_FILE"
fi
