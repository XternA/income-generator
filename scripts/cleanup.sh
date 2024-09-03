#!/bin/sh

[ "$(uname)" = 'Darwin' ] && rm -rf "$ENV_FILE.bak" "$ENV_SYSTEM_FILE.bak"
