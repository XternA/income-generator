#!/bin/sh

ACTION="$1"
TARGET_FILE="$2"
TEMP_FILE="${TARGET_FILE}.tmp"
KEY_FILE="${TARGET_FILE}.key"

usage() {
    echo "Usage: $0 [-e <path_to_file>] [-d <path_to_file>]"
    exit 1
}

generate_key() {
    if [ ! -f "$KEY_FILE" ]; then
        openssl rand -base64 32 > "$KEY_FILE"
        chmod 400 "$KEY_FILE"
        echo "Key file generated: $KEY_FILE"
    fi
}

encrypt_file() {
    if [ ! -f "$TARGET_FILE" ]; then
        echo "Error: file not found at '$TARGET_FILE'"
        exit 1
    fi
    generate_key
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$TARGET_FILE" -out "$TEMP_FILE" -pass file:"$KEY_FILE"
    if [ $? -eq 0 ]; then
        mv "$TEMP_FILE" "$TARGET_FILE"
        echo "File encrypted: $TARGET_FILE"
    else
        echo "Error encrypting the file"
        rm -f "$TEMP_FILE"
        exit 1
    fi
}

decrypt_file() {
    if [ ! -f "$TARGET_FILE" ]; then
        echo "Error: encrypted file not found at '$TARGET_FILE'"
        exit 1
    fi
    if [ ! -f "$KEY_FILE" ]; then
        echo "Error: key file not found at '$KEY_FILE'. Cannot decrypt."
        exit 1
    fi
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$TARGET_FILE" -out "$TEMP_FILE" -pass file:"$KEY_FILE"
    if [ $? -eq 0 ]; then
        mv "$TEMP_FILE" "$TARGET_FILE"
        echo "File decrypted: $TARGET_FILE"
        rm -f "$KEY_FILE"
    else
        echo "Error decrypting file"
        rm -f "$TEMP_FILE"
        exit 1
    fi
}

# Main script
[ "$#" -ne 2 ] && usage

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: openssl is not installed."
    exit 1
fi

case "$ACTION" in
    -e) encrypt_file ;;
    -es) encrypt_file > /dev/null 2>&1 ;;
    -d) decrypt_file ;;
    -ds) decrypt_file > /dev/null 2>&1 ;;
    *) usage ;;
esac
