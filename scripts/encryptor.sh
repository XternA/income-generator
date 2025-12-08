#!/bin/sh

usage() {
    echo "Usage: $0 [-e <path_to_file>] [-d <path_to_file>]"
    exit 1
}

ACTION="$1"
TARGET_FILE="$2"
TEMP_FILE="${TARGET_FILE}.tmp"
KEY_FILE="${TARGET_FILE}.key"
LOCK_FILE="${TARGET_FILE}.lock"

# Ensure cleanup on exit/interrupt
cleanup() {
    rm -rf "$LOCK_FILE" "$TEMP_FILE" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Create lock file with PID
acquire_lock() {
    # Try to create lock file atomically
    if mkdir "$LOCK_FILE" 2>/dev/null; then
        echo $$ > "$LOCK_FILE/pid"
        return 0
    else
        # Check if lock is stale
        if [ -f "$LOCK_FILE/pid" ]; then
            LOCK_PID=$(cat "$LOCK_FILE/pid")
            if ! kill -0 "$LOCK_PID" 2>/dev/null; then
                # Stale lock, remove it
                rm -rf "$LOCK_FILE"
                mkdir "$LOCK_FILE" 2>/dev/null && echo $$ > "$LOCK_FILE/pid"
                return 0
            fi
        fi
        return 1
    fi
}

is_encrypted() {
    # OpenSSL encrypted files start with "Salted__"
    head -c 8 "$TARGET_FILE" 2>/dev/null | grep -q "^Salted__"
}

generate_key() {
    if [ ! -f "$KEY_FILE" ]; then
        openssl rand -base64 32 > "$KEY_FILE"
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

    generate_key
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$TARGET_FILE" -out "$TEMP_FILE" -pass file:"$KEY_FILE" 2>/dev/null

    if [ $? -eq 0 ]; then
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

    # Acquire lock
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

    if [ ! -f "$KEY_FILE" ]; then
        echo "Error: key file not found at '$KEY_FILE'. Cannot decrypt." >&2
        exit 1
    fi

    openssl enc -aes-256-cbc -d -pbkdf2 -in "$TARGET_FILE" -out "$TEMP_FILE" -pass file:"$KEY_FILE" 2>/dev/null

    if [ $? -eq 0 ]; then
        mv "$TEMP_FILE" "$TARGET_FILE"
        echo "File decrypted: $TARGET_FILE"
        rm -f "$KEY_FILE"  # Delete key after decryption - new key generated on next encrypt
    else
        echo "Error decrypting file" >&2
        exit 1
    fi
}

# Main script
[ "$#" -ne 2 ] && usage

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: openssl is not installed." >&2
    exit 1
fi

case "$ACTION" in
    -e) encrypt_file ;;
    -es) encrypt_file > /dev/null 2>&1 ;;
    -d) decrypt_file ;;
    -ds) decrypt_file > /dev/null 2>&1 ;;
    *) usage ;;
esac
