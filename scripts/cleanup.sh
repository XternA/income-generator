#!/bin/sh

if [ "$(uname)" = 'Darwin' ]; then rm -rf "$ENV_FILE.bak" "$ENV_SYSTEM_FILE.bak"
