#!/usr/bin/env sh

DISTRO="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
TARGET="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"

ensure_bookworm_for_xautolock() {
  CODENAME=""
  VERMAJOR=""
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    CODENAME="${VERSION_CODENAME:-}"
    VERMAJOR="${VERSION_ID%%.*}"
  fi

  if [ "${CODENAME}" = "trixie" ] || [ "${VERMAJOR}" = "13" ]; then
    echo "[xautolock] Configuring bookworm repo + pinning (Debian 13 detected)"
    cat >/etc/apt/sources.list.d/bookworm.list <<'EOF'
deb http://deb.debian.org/debian bookworm main
deb http://security.debian.org/debian-security bookworm-security main
EOF

    cat >/etc/apt/preferences.d/xautolock-from-bookworm <<'EOF'
Package: *
Pin: release n=bookworm
Pin-Priority: -10

Package: *
Pin: release n=bookworm-security
Pin-Priority: -10

Package: xautolock
Pin: release n=bookworm
Pin-Priority: 1001
EOF
  fi
}

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
      ensure_bookworm_for_xautolock
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
        $(apt-cache search libopenh264 | grep -oE 'libopenh264-[0-9]+' | head -n1) \
        libopus0 \
        libdrm2 || exit 1
      rm -rf /var/lib/apt/lists/*
      ;;
esac

echo "Cleaning up: removing $0"
rm -f -- "$0"
