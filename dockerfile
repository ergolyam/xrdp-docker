FROM alpine:latest

RUN apk add --no-cache \
       openssl \
       dbus \
       xorg-server \
       icewm \
       xkeyboard-config \
       setxkbmap \
       tzdata \
       xdg-utils

RUN apk add --no-cache \
        --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
        xrdp xorgxrdp

ENV TZ=UTC

COPY rootfs /

EXPOSE 3389

CMD ["/usr/bin/start.sh"]
