#!/bin/sh

[ "$(uname)" = 'Darwin' ] && rm -rf "$ENV_FILE.bk" "$ENV_SYSTEM_FILE.bk"
