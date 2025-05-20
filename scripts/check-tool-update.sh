#!/bin/sh

case "$1" in
    --update)
        printf "Checking for new updates available...\n\n"

        git fetch --quiet
        if [ "$(git rev-list HEAD..@{u} --count)" -gt 0 ]; then
            printf "New updates available! 🚀"
            sleep 1.4
            printf "\rUpdating to latest version...\n\n"
            git pull --quiet > /dev/null 2>&1
            sleep 1.2
            echo "Update complete ✅"
        else
            echo "No update available ❌"
        fi
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
