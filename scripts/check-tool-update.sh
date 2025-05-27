#!/bin/sh

case "$1" in
    --update)
        printf "Checking for new updates available...\n\n"

        git fetch --quiet
        if [ "$(git rev-list HEAD..@{u} --count)" -gt 0 ]; then
            printf "New update available 🚀\nDo you want to update now? [Y/N]: "
            read answer
            case "$answer" in
                [Yy]*)
                    printf "\nUpdating to latest version..."
                    git reset --hard --quiet && git pull --quiet
                    sleep 1.2
                    printf "\rUpdate complete ✅            \n"
                    ;;
                *)
                    printf "\nUpdate skipped ❌\n"
                    ;;
            esac
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
        COMPARE_COMMITS=$(curl -s --connect-timeout 2 --max-time 5 "$URL/$REPO/compare/$TAG_COMMIT...$LOCAL_COMMIT" | jq -r '.status' 2>/dev/null)

        [ "$COMPARE_COMMITS" = "behind" ] && printf "\033[5m\033[91m%s\033[0m\n" "New tool update available! 🚀\n"
esac
