#!/bin/sh

ACTION="$1"
TARGET_FILE="$2"
TEMP_FILE="${TARGET_FILE}.tmp"
KEY_FILE="${TARGET_FILE}.key"
LOCK_FILE="${TARGET_FILE}.lock"

cleanup() {
    rm -rf "$LOCK_FILE" "$TEMP_FILE" 2>/dev/null
    [ ! -s "$KEY_FILE" ] && rm -f "$KEY_FILE" 2>/dev/null
}
trap cleanup EXIT INT TERM HUP

acquire_lock() {
    if mkdir "$LOCK_FILE" 2>/dev/null; then
        echo $$ > "$LOCK_FILE/pid"
        return 0
    fi
    read -r LOCK_PID < "$LOCK_FILE/pid" 2>/dev/null || return 1
    kill -0 "$LOCK_PID" 2>/dev/null && return 1
    rm -rf "$LOCK_FILE"
    mkdir "$LOCK_FILE" 2>/dev/null && echo $$ > "$LOCK_FILE/pid" && return 0
    return 1
}

is_encrypted() {
    # OpenSSL encrypted files start with "Salted__"
    head -c 8 "$TARGET_FILE" 2>/dev/null | grep -qF "Salted__"
}

generate_key() {
    if [ ! -s "$KEY_FILE" ]; then
        openssl rand -base64 32 > "$KEY_FILE" || { rm -f "$KEY_FILE"; return 1; }
        chmod 400 "$KEY_FILE"
    fi
}

encrypt_file() {
    if [ ! -f "$TARGET_FILE" ]; then
        echo "Error: file not found at '$TARGET_FILE'" >&2
        exit 1
    fi

    if ! acquire_lock; then
        echo "Another IGM instance is managing encryption. Skipping." >&2
        exit 0
    fi

    if is_encrypted; then
        echo "File already encrypted. Skipping." >&2
        exit 0
    fi

    generate_key || { echo "Error generating encryption key" >&2; exit 1; }

    if openssl enc -aes-256-cbc -salt -pbkdf2 -in "$TARGET_FILE" -out "$TEMP_FILE" -pass file:"$KEY_FILE" 2>/dev/null; then
        mv "$TEMP_FILE" "$TARGET_FILE"
        echo "File encrypted: $TARGET_FILE"
    else
        echo "Error encrypting the file" >&2
        exit 1
    fi
}

decrypt_file() {
    if [ ! -f "$TARGET_FILE" ]; then
        echo "Error: encrypted file not found at '$TARGET_FILE'" >&2
        exit 1
    fi

    if ! acquire_lock; then
        # Another instance is decrypting - wait and check if decryption completes
        # 60 iterations × 0.05s = 3 second timeout
        i=0
        while [ $i -lt 60 ]; do
            sleep 0.05
            if ! is_encrypted; then
                echo "File already decrypted by another instance."
                exit 0
            fi
            i=$((i + 1))
        done
        echo "Timeout waiting for decryption." >&2
        exit 1
    fi

    if ! is_encrypted; then
        echo "File already decrypted. Skipping."
        exit 0
    fi

    if [ ! -s "$KEY_FILE" ]; then
        echo "Error: key file not found at '$KEY_FILE'. Cannot decrypt." >&2
        exit 1
    fi

    if openssl enc -aes-256-cbc -d -pbkdf2 -in "$TARGET_FILE" -out "$TEMP_FILE" -pass file:"$KEY_FILE" 2>/dev/null; then
        mv "$TEMP_FILE" "$TARGET_FILE"
        echo "File decrypted: $TARGET_FILE"
        rm -f "$KEY_FILE"  # Delete key after decryption - new key generated on next encrypt
    else
        echo "Error decrypting file" >&2
        exit 1
    fi
}

# Main script
if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: openssl is not installed." >&2
    exit 1
fi

case "$ACTION" in
    -e) encrypt_file ;;
    -es) encrypt_file > /dev/null 2>&1 ;;
    -d) decrypt_file ;;
    -ds) decrypt_file > /dev/null 2>&1 ;;
esac
