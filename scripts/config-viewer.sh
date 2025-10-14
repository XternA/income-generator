#!/bin/sh

FILE=${1:-"$ENV_FILE"}

if [ ! -e "$FILE" ]; then
    printf 'Nothing to view as file does not exist.\n'
    exit 1
fi

TYPE=${2:-CONFIG}
COMMENT="\033[90m" # Grey

printf "${YELLOW}---------[ START OF $TYPE ]---------\n${RED}\n"

if [ "$TYPE" = "PROXY" ]; then
    awk -v COMMENT="$COMMENT" -v NC="$NC" '
        /^#/ { print COMMENT $0 NC; next }
        { print }
    ' "$FILE"
else
    awk -v KEY="$BLUE" -v EQUALS="$RED" -v VALUE="$GREEN" -v COMMENT="$COMMENT" -v NC="$NC" '
        /^##/ { print COMMENT $0 NC; next }
        /=/ {
            # split on first = only
            i = index($0, "=")
            if (i > 0) {
                key = substr($0, 1, i-1)
                value = substr($0, i+1)
                printf "%s%s%s=%s%s%s\n", KEY, key, EQUALS, VALUE, value, NC
            } else {
                print $0
            }
            next
        }
        { print }
    ' "$FILE"
fi

printf "${YELLOW}\n----------[ END OF $TYPE ]----------${NC}\n"
printf '\nPress Enter to continue...'; read -r _
