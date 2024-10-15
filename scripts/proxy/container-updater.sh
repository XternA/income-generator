#!/bin/sh

WATCHTOWER_COMPOSE="$COMPOSE_DIR/compose.yml"
COMMAND="$CONTAINER_COMPOSE $DEFAULT_ENV_FILES -f $WATCHTOWER_COMPOSE up --force-recreate --build -d"

deploy_watchtower() {
    cp "$WATCHTOWER_COMPOSE" "$WATCHTOWER_COMPOSE.bak"

    awk '/--rolling-restart/ { next } { print }' "$WATCHTOWER_COMPOSE" > temp && mv temp "$WATCHTOWER_COMPOSE"
    $COMMAND > /dev/null 2>&1

    mv "${WATCHTOWER_COMPOSE}.bak" "$WATCHTOWER_COMPOSE"
}


restore_watchtower() {
    CONTAINER_EXIST="$CONTAINER_ALIAS ps -a -q -f 'name=watchtower'"
    [ -z "$(eval $CONTAINER_EXISTS)" ] && eval $COMMAND > /dev/null 2>&1
}

case "$1" in
    deploy) deploy_watchtower ;;
    restore) restore_watchtower ;;
esac
