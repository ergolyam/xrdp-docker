#!/usr/bin/env sh
set -eu

if [ ! -f /startapp.sh ]; then
  echo "startapp.sh not found."
  exit 1
fi

if [ -f /var/run/xrdp-sesman.pid ]; then
  rm -f /var/run/xrdp-sesman.pid
fi

: "${USER:?env USER is not set}"
: "${PASSWD:?env PASSWD is not set}"
: "${USER_UID:?env USER_UID is not set}"
: "${USER_GID:?env USER_GID is not set}"

validate_positive_integer() {
  case "$2" in
    ''|*[!0-9]*)
      echo "$1 must be a positive integer, got: $2"
      exit 1
      ;;
  esac

  [ "$2" -gt 0 ] || {
    echo "$1=0 is not allowed."
    exit 1
  }
}

validate_positive_integer USER_UID "$USER_UID"
validate_positive_integer USER_GID "$USER_GID"

if [ "${DARK_MODE:-}" = "true" ]; then
  : > /tmp/darkmode
fi

if [ -n "${LOGOUT_TIMEOUT:-}" ]; then
  printf '%s\n' "${LOGOUT_TIMEOUT}" > /tmp/timeout
fi

if ! id "$USER" >/dev/null 2>&1; then
  if adduser --help 2>&1 | grep -- ' -D' >/dev/null 2>&1; then
    if ! getent group "$USER" >/dev/null 2>&1; then
      addgroup -g "$USER_GID" "$USER"
    fi
    adduser -D -u "$USER_UID" -G "$USER" "$USER"
  else
    if ! getent group "$USER" >/dev/null 2>&1; then
      addgroup --gid "$USER_GID" "$USER"
    fi
    adduser --disabled-password --gecos "" --uid "$USER_UID" --ingroup "$USER" "$USER"
  fi
fi

UID=$(id -u "$USER")
printf '%s\n' "$USER:$PASSWD" | chpasswd

if [ -f /entrypoint.sh ]; then
  /entrypoint.sh
fi

/usr/bin/set-layout.sh

if [ ! -f /etc/machine-id ]; then
  mkdir -p /var/run/dbus
  dbus-uuidgen --ensure
fi

if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  printf '%s\n' "${TZ}" > /etc/timezone
fi

if [ "${PORT:-}" ]; then
  sed -i "s/^port=3389$/port=${PORT}/" /etc/xrdp/xrdp.ini
fi

if [ "${DISPLAY:-}" ]; then
  echo "Use X DISPLAY: $DISPLAY"
  sed -i "s/^X11DisplayOffset=10$/X11DisplayOffset=${DISPLAY}/" /etc/xrdp/sesman.ini
  sed -i "s/^export DISPLAY=:10/export DISPLAY=:${DISPLAY}/" /etc/xrdp/startwm.sh
fi

/usr/sbin/xrdp-sesman -n &
SESMAN_PID=$!

/usr/sbin/xrdp -n &
XRDP_PID=$!

term_handler() {
    echo ">>> Caught SIGTERM – shutting down xrdp cleanly…"
    if [ -d "/var/run/xrdp/$UID" ]; then
        XRDP_DISPLAY=$(
            ls /var/run/xrdp/"$UID"/xrdp_display_* 2>/dev/null \
            | head -n 1 | awk -F_ '{print ":"$NF}'
        )
        su - "$USER" -c "DISPLAY=$XRDP_DISPLAY icesh logout" 2>/dev/null || true
        sleep 2
    fi
    kill -TERM "$XRDP_PID" "$SESMAN_PID" 2>/dev/null || true
    wait "$XRDP_PID" 2>/dev/null || true
    wait "$SESMAN_PID" 2>/dev/null || true
    exit 0
}

trap term_handler TERM INT

while kill -0 "$XRDP_PID" 2>/dev/null && kill -0 "$SESMAN_PID" 2>/dev/null; do
  sleep 1
done
term_handler
