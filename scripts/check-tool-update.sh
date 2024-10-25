#!/bin/sh

case "$1" in
    --update)
        echo "\nChecking and attempting to get latest updates...\n"
        git fetch; git reset --hard; git pull
        ;;
    *)
        URL="https://api.github.com/repos"
        REPO="xterna/income-generator"

        RELEASE_VERSION=$(curl -s --connect-timeout 2 --max-time 5 "$URL/$REPO/releases/latest" | jq -r '.tag_name'); [ -z "$RELEASE_VERSION" ] && exit 0
        TAG_COMMIT=$(curl -s "$URL/$REPO/tags" | jq -r --arg tag "$RELEASE_VERSION" '.[] | select(.name == $tag) | .commit.sha' | head -n 1); [ -z "$TAG_COMMIT" ] && exit 0
        LOCAL_COMMIT=$(git rev-parse HEAD)
        COMPARE_COMMITS=$(curl -s --connect-timeout 2 --max-time 5 "$URL/$REPO/compare/$TAG_COMMIT...$LOCAL_COMMIT" | jq -r '.status')

        [ "$COMPARE_COMMITS" = "behind" ] && printf "\033[5m\033[91m%s\033[0m\n" "New tool update available! 🚀"
        ;;
esac
