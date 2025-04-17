FROM alpine:latest

RUN apk add --no-cache \
       openssl \
       dbus \
       xrdp \
       xorgxrdp \
       xorg-server \
       icewm \
       xkeyboard-config \
       setxkbmap \
       tzdata \
       xdg-utils

ENV TZ=UTC

COPY rootfs /

EXPOSE 3389

CMD ["/usr/bin/start.sh"]
