#!/bin/sh

[ -n "$BANNER_CACHED" ] && return
BANNER_CACHED=1

. scripts/colours.sh

display_banner() {
    clear
    printf "Income Generator Application Manager\n"
    printf "${GREEN}------------------------------------------${NC}\n"
    [ ! "$1" = "--noline" ] && echo
}
