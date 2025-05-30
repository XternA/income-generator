#!/bin/sh

FILE=${1:-"$ENV_FILE"}

if [ ! -e "$FILE" ]; then
    echo "Nothing to view as file doesn't exist."
else
    TYPE=${2:-"CONFIG"}

    KEY='\x1b[94m'     # Blue
    EQUALS='\x1b[91m'  # Red
    VALUE='\x1b[92m'   # Green
    COMMENT='\x1b[90m' # Grey
    RESET='\x1b[0m'    # Reset

    printf "${YELLOW}---------[ START OF $TYPE ]---------\n${RED}\n"
    if [ "$TYPE" = "PROXY" ]; then
        cat "$FILE" | sed -e "s/^#.*$/\x1b[90m&\x1b[0m/"
    else
        cat "$FILE" | sed -e "s/^\([^=]*\)=\(.*\)$/${KEY}\1${EQUALS}=${VALUE}\2${RESET}/" -e "s/^##.*/${COMMENT}&${RESET}/"
    fi
    printf "${YELLOW}\n----------[ END OF $TYPE ]----------${NC}\n"
fi

printf "\nPress Enter to continue..."; read -r input
