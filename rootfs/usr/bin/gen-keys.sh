#!/usr/bin/env sh

set -eu

umask 077

KEYS_DIR="/keys"

CERT_FILE="${KEYS_DIR}/cert.pem"
KEY_FILE="${KEYS_DIR}/key.pem"

RSA_KEYS_FILE="${KEYS_DIR}/rsakeys.ini"
RSA_KEYS_LINK="/etc/xrdp/rsakeys.ini"

require_writable_dir() {
    dir=$1

    if [ ! -d "$dir" ]; then
        echo "ERROR: Directory does not exist: $dir" >&2
        exit 1
    fi

    if [ ! -w "$dir" ]; then
        echo "ERROR: Directory is not writable: $dir" >&2
        exit 1
    fi
}

if [ ! -s "$RSA_KEYS_FILE" ]; then
    require_writable_dir "$KEYS_DIR"
    echo "Generating xrdp RSA keys..."

    rm -f "$RSA_KEYS_FILE"
    xrdp-keygen xrdp "$RSA_KEYS_FILE"
    chmod 600 "$RSA_KEYS_FILE"
fi

if [ ! -L "$RSA_KEYS_LINK" ] || [ "$(readlink "$RSA_KEYS_LINK")" != "$RSA_KEYS_FILE" ]; then
    rm -f "$RSA_KEYS_LINK"
    ln -s "$RSA_KEYS_FILE" "$RSA_KEYS_LINK"
fi

if [ ! -s "$CERT_FILE" ] || [ ! -s "$KEY_FILE" ]; then
    require_writable_dir "$KEYS_DIR"
    echo "Generating xrdp TLS certificate..."

    rm -f "$KEY_FILE" "$CERT_FILE"
    openssl req -x509 -newkey rsa:2048 -nodes -keyout "$KEY_FILE" -out "$CERT_FILE" -days 365 -subj "/CN=xrdp"
    chmod 600 "$KEY_FILE"
    chmod 644 "$CERT_FILE"
fi
