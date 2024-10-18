#!/bin/sh

WATCHTOWER_COMPOSE="$COMPOSE_DIR/compose.yml"
COMMAND="$CONTAINER_COMPOSE $DEFAULT_ENV_FILES -f $WATCHTOWER_COMPOSE up --force-recreate --build -d"
WATCHTOWER_ALIAS="watchtower"

modify_watchtower() {
    cp "$WATCHTOWER_COMPOSE" "$WATCHTOWER_COMPOSE.bak" > /dev/null 2>&1
    awk '/--rolling-restart/ { next } { print }' "$WATCHTOWER_COMPOSE" > temp && mv temp "$WATCHTOWER_COMPOSE"
}

restore_watchtower() {
    mv "${WATCHTOWER_COMPOSE}.bak" "$WATCHTOWER_COMPOSE" > /dev/null 2>&1
}

deploy_for_proxy() {
    modify_watchtower
    $CONTAINER_COMPOSE $DEFAULT_ENV_FILES -f $WATCHTOWER_COMPOSE pull > /dev/null 2>&1
    $COMMAND > /dev/null 2>&1
    restore_watchtower
}

restore_for_standard() {
    have_active_apps="$($CONTAINER_ALIAS ps -a --filter "label=project=standard" --format "{{.Names}}" | grep -v "$WATCHTOWER_ALIAS" | head -n 1)"

    if [ ! -z "$have_active_apps" ]; then
        CONTAINER_EXIST="$CONTAINER_ALIAS ps -a -q -f 'name=$WATCHTOWER_ALIAS'"
        [ -z "$(eval $CONTAINER_EXISTS)" ] && eval $COMMAND > /dev/null 2>&1
    else
        $CONTAINER_ALIAS rm -f $WATCHTOWER_ALIAS > /dev/null 2>&1
    fi
}

case "$1" in
    deploy) deploy_for_proxy ;;
    restore) restore_for_standard ;;
    modify_only) modify_watchtower ;;
    restore_only) restore_watchtower ;;
esac
