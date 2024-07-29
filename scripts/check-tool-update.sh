#!/bin/sh

REPO="xterna/income-generator"

check_for_update() {
    RELEASE_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r '.tag_name // empty'); [ -z "$RELEASE_VERSION" ] && exit 0
    TAG_COMMIT=$(curl -s "https://api.github.com/repos/$REPO/tags" | jq -r --arg tag "$RELEASE_VERSION" '.[] | select(.name == $tag) | .commit.sha'); [ -z "$TAG_COMMIT" ] && exit 0
    LOCAL_COMMIT=$(git rev-parse HEAD)
    COMPARE_COMMITS=$(curl -s "https://api.github.com/repos/$REPO/compare/$TAG_COMMIT...$LOCAL_COMMIT" | jq -r '.status // empty')

    if [ "$COMPARE_COMMITS" = "behind" ]; then
        printf "\033[5m\033[91m%s\033[0m\n" "New tool update available! 🚀"
    fi
}

update() {
    echo "\nChecking and attempting to get latest updates...\n"
    git fetch; git reset --hard; git pull
}

# Main
if [ "$1" = "--update" ]; then
    update
else
    check_for_update
fi
