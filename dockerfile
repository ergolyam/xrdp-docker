ARG PKG_DIR=/xrdp-install

FROM alpine:latest AS builder

ARG PKG_DIR

ARG XRDP_VER=v0.10.3

RUN apk add --no-cache build-base git autoconf automake check-dev cmocka-dev libtool openssl-dev \
    libx11-dev libxfixes-dev libxrandr-dev libjpeg-turbo-dev \
    linux-headers nasm linux-pam-dev opus-dev libdrm-dev \
    xorg-server-dev openh264-dev x264-dev

WORKDIR /build/xrdp
RUN git clone --depth 1 -b $XRDP_VER https://github.com/neutrinolabs/xrdp.git .
RUN wget https://gitlab.alpinelinux.org/alpine/aports/-/raw/89dc4b937a7591002c9f8d437d0efe4eabaeea99/community/xrdp/dynamic-link.patch
RUN wget https://gitlab.alpinelinux.org/alpine/aports/-/raw/89dc4b937a7591002c9f8d437d0efe4eabaeea99/community/xrdp/remove-werror.patch
RUN patch -p1 < ./dynamic-link.patch && patch -p1 < ./remove-werror.patch
RUN sed -i 's|^param=Xorg|param=/usr/libexec/Xorg|' sesman/sesman.ini.in
RUN ./bootstrap
RUN ./configure --prefix=/usr \
    --disable-static \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --sbindir=/usr/sbin \
    --enable-ipv6 \
    --enable-openh264 \
    --enable-x264 \
    --enable-opus \
    --enable-pam \
    --enable-tjpeg \
    --enable-vsock \
    --without-simd
RUN make -j$(nproc)
RUN make install && make DESTDIR=$PKG_DIR install
RUN wget -O $PKG_DIR/etc/xrdp/openssl.conf https://gitlab.alpinelinux.org/alpine/aports/-/raw/89dc4b937a7591002c9f8d437d0efe4eabaeea99/community/xrdp/openssl.conf
RUN rm -f $PKG_DIR/etc/xrdp/*.pem $PKG_DIR/etc/xrdp/rsakeys.ini

WORKDIR /build/xorgxrdp
RUN git clone --depth 1 -b $XRDP_VER https://github.com/neutrinolabs/xorgxrdp.git .
RUN ./bootstrap
RUN ./configure --prefix=/usr \
    --sysconfdir=/etc \
    --mandir=/usr/share/man \
    --localstatedir=/var
RUN make -j$(nproc)
RUN make install && make DESTDIR=$PKG_DIR install


FROM alpine:latest AS main

ARG PKG_DIR

RUN apk add --no-cache \
    openssl \
    dbus \
    xorg-server \
    icewm \
    xkeyboard-config \
    setxkbmap \
    tzdata \
    xdg-utils \
    linux-pam \
    libjpeg-turbo \
    libturbojpeg \
    openh264 \
    x264-libs \
    opus \
    libdrm

COPY --from=builder $PKG_DIR/ /

RUN wget -qO- https://gitlab.alpinelinux.org/alpine/aports/-/raw/89dc4b937a7591002c9f8d437d0efe4eabaeea99/community/xrdp/xrdp.post-install | sh

ENV TZ=UTC

COPY rootfs /

EXPOSE 3389

CMD ["/usr/bin/start.sh"]
