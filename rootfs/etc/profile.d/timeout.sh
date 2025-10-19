#!/usr/bin/env sh

TIMEFILE=/tmp/timeout

[ -s "$TIMEFILE" ] || return

[ -r "$TIMEFILE" ] && timeout=$(tr -d '[:space:]' < "$TIMEFILE")

case "$timeout" in
    ''|*[!0-9]*)
        return
        ;;
    0|00)
        return
        ;;
esac

pgrep -u "$USER" -x xautolock >/dev/null &&
    return

xautolock -time "$timeout" -detectsleep -locker "icesh logout" &
