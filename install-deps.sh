#!/usr/bin/env sh

DISTRO="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
TARGET="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"

case "${DISTRO}_${TARGET}" in
    alpine_builder)
      apk add --no-cache \
        build-base \
        git \
        autoconf \
        automake \
        check-dev \
        cmocka-dev \
        libtool \
        openssl-dev \
        libx11-dev \
        libxfixes-dev \
        libxrandr-dev \
        libjpeg-turbo-dev \
        linux-headers \
        nasm \
        linux-pam-dev \
        opus-dev \
        libdrm-dev \
        xorg-server-dev \
        openh264-dev || exit 1
      ;;
    alpine_main)
      apk add --no-cache \
        openssl \
        dbus \
        xorg-server \
        icewm \
        xkeyboard-config \
        xautolock \
        setxkbmap \
        tzdata \
        xdg-utils \
        linux-pam \
        libjpeg-turbo \
        libturbojpeg \
        openh264 \
        opus \
        libdrm || exit 1
      ;;
    debian_builder)
      apt-get update -y
      apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        build-essential \
        git \
        autoconf \
        automake \
        check \
        libturbojpeg0-dev \
        libcmocka-dev \
        libopus-dev \
        libpam0g-dev \
        libssl-dev \
        libtool \
        libx11-dev \
        libxfixes-dev \
        libxrandr-dev \
        libdrm-dev \
        xserver-xorg-dev \
        nasm \
        libpam0g-dev \
        libopus-dev \
        libdrm-dev \
        pkgconf \
        libopenh264-dev || exit 1
      rm -rf /var/lib/apt/lists/*
      ;;
    debian_main)
      apt-get update -y
      apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        openssl \
        dbus \
        xserver-xorg-core \
        icewm \
        xkb-data \
        xautolock \
        x11-xkb-utils \
        tzdata \
        xdg-utils \
        libpam0g \
        libjpeg62-turbo \
        libturbojpeg0 \
        libopenh264-7 \
        libopus0 \
        libdrm2 || exit 1
      rm -rf /var/lib/apt/lists/*
      ;;
esac

echo "Cleaning up: removing $0"
rm -f -- "$0"
