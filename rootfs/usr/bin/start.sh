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

if [ "${DARK_MODE:-}" = "true" ]; then
  : > /tmp/darkmode
fi

if [ -n "${LOGOUT_TIMEOUT:-}" ]; then
  printf '%s\n' "${LOGOUT_TIMEOUT}" > /tmp/timeout
fi

if ! id "$USER" >/dev/null 2>&1; then
  if adduser --help 2>&1 | grep -- ' -D' >/dev/null 2>&1; then
    adduser -D "$USER"
  else
    adduser --disabled-password --gecos "" "$USER"
  fi
fi

UID=$(id -u "$USER")
printf '%s\n' "$USER:$PASSWD" | chpasswd

if [ -f /entrypoint.sh ]; then
  /entrypoint.sh
fi

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

