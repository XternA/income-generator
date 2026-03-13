#!/bin/sh

[ -n "$__COLOURS_CACHED" ] && return
__COLOURS_CACHED=1

if [ "$COLORTERM" = "truecolor" ] || [ "$COLORTERM" = "24bit" ]; then
    export RED='\033[1;38;2;255;105;135m'
    export GREEN='\033[1;38;2;120;255;180m'
    export BLUE='\033[1;38;2;150;240;255m'
    export YELLOW='\033[1;38;2;255;190;80m'
    export PINK='\033[1;38;2;255;121;198m'
    export GREY='\033[38;2;50;50;50m'
else
    export RED='\033[1;91m'
    export GREEN='\033[1;92m'
    export BLUE='\033[1;96m'
    export YELLOW='\033[1;93m'
    export PINK='\033[1;95m'
    export GREY='\033[90m'
fi
export NC='\033[0m'
