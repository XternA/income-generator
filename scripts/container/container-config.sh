#!/bin/sh

export CONTAINER_ALIAS="docker"

if docker compose version > /dev/null 2>&1; then
    export CONTAINER_COMPOSE="$CONTAINER_ALIAS compose"
else
    export CONTAINER_COMPOSE="$CONTAINER_ALIAS-compose"
fi
