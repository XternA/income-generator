#!/bin/sh

ENV_FILE="$(pwd)/.env"

if [ $(uname) = 'Darwin' ]; then
    rm -rf $ENV_FILE".bak"
fi
