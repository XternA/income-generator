#!/bin/sh

run_darwin() {
    if [ $(uname) = 'Darwin' ]; then

        if ! command -v brew > /dev/null 2>&1; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            sleep 2.5
        fi
    fi
}

run_darwin
sh "$(pwd)/scripts/jq-install.sh"
