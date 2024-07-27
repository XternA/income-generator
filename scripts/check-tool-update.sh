#!/bin/sh

REPO="xterna/income-generator"

check_for_update() {
    RELEASE_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r '.tag_name // empty')
    [ -z "$RELEASE_TAG" ] && exit 0

    RELEASE_COMMIT=$(git rev-parse "refs/tags/$RELEASE_TAG")
    BEHIND_COUNT=$(git rev-list --count "origin/main..$RELEASE_COMMIT")

    if [ "$BEHIND_COUNT" -gt 0 ]; then
        printf "\033[5m\033[91m%s\033[0m\n" "New tool update available! 🚀"
    fi
}

update() {
    echo "\nChecking and attempting to get the latest updates...\n"
    git fetch; git reset --hard; git pull
}

# Main
if [ "$1" = "--update" ]; then
    update
else
    check_for_update
fi
