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
          openh264-dev
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
        libdrm
      ;;
esac

echo "Cleaning up: removing $0"
rm -f -- "$0"
