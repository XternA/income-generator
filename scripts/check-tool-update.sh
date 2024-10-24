#!/bin/sh

case "$1" in
    --update)
        echo "\nChecking and attempting to get latest updates...\n"
        git fetch; git reset --hard; git pull
        ;;
    *)
        URL="https://api.github.com/repos"
        REPO="xterna/income-generator"

        RELEASE_VERSION=$(curl -s "$URL/$REPO/releases/latest" | jq -r '.tag_name // empty'); [ -z "$RELEASE_VERSION" ] && exit 0
        TAG_COMMIT=$(curl -s "$URL/$REPO/tags" | jq -r --arg tag "$RELEASE_VERSION" '.[] | select(.name == $tag) | .commit.sha'); [ -z "$TAG_COMMIT" ] && exit 0
        LOCAL_COMMIT=$(git rev-parse HEAD)
        COMPARE_COMMITS=$(curl -s "$URL/$REPO/compare/$TAG_COMMIT...$LOCAL_COMMIT" | jq -r '.status // empty')

        [ "$COMPARE_COMMITS" = "behind" ] && printf "\033[5m\033[91m%s\033[0m\n" "New tool update available! 🚀"
        ;;
esac
