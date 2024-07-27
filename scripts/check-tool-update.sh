#!/bin/sh

REPO="xterna/income-generator"

check_for_update() {
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r '.tag_name // empty')
    [ -z "$LATEST_RELEASE" ] && exit 0
    CURRENT_BRANCH=$(git rev-parse HEAD)

    if git merge-base --is-ancestor "$CURRENT_BRANCH" "$LATEST_RELEASE"; then
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
