ARG VERSION=latest
ARG DIST=alpine

ARG PKG_DIR=/xrdp-install

FROM ${DIST}:${VERSION} AS base


FROM base AS builder

ARG DIST

ARG PKG_DIR

ARG XRDP_VER=v0.10.3

ARG XORGRDP_VER=v0.10.4

COPY install-deps.sh ./install-deps.sh
RUN ./install-deps.sh ${DIST} builder

WORKDIR /build/xrdp
RUN git clone --depth 1 -b $XRDP_VER https://github.com/neutrinolabs/xrdp.git .
RUN [ "${DIST}" = "debian" ] || wget https://gitlab.alpinelinux.org/alpine/aports/-/raw/89dc4b937a7591002c9f8d437d0efe4eabaeea99/community/xrdp/dynamic-link.patch
RUN [ "${DIST}" = "debian" ] || wget https://gitlab.alpinelinux.org/alpine/aports/-/raw/89dc4b937a7591002c9f8d437d0efe4eabaeea99/community/xrdp/remove-werror.patch
RUN [ "${DIST}" = "debian" ] || patch -p1 < ./dynamic-link.patch
RUN [ "${DIST}" = "debian" ] || patch -p1 < ./remove-werror.patch

RUN if [ "$DIST" = "alpine" ]; then \
      sed -i 's|^param=Xorg|param=/usr/libexec/Xorg|' sesman/sesman.ini.in; \
    elif [ "$DIST" = "debian" ]; then \
      sed -i 's|^param=Xorg|param=/usr/lib/xorg/Xorg|' sesman/sesman.ini.in; \
    fi

RUN ./bootstrap
RUN ./configure --prefix=/usr \
    --disable-static \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --sbindir=/usr/sbin \
    --enable-ipv6 \
    --enable-openh264 \
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
RUN git clone --depth 1 -b $XORGRDP_VER https://github.com/neutrinolabs/xorgxrdp.git .
RUN ./bootstrap
RUN ./configure --prefix=/usr \
    --sysconfdir=/etc \
    --mandir=/usr/share/man \
    --localstatedir=/var \
    --without-simd
RUN make -j$(nproc)
RUN make install && make DESTDIR=$PKG_DIR install


FROM base AS main

ARG DIST

ARG PKG_DIR

COPY install-deps.sh ./install-deps.sh
RUN ./install-deps.sh ${DIST} main

COPY --from=builder $PKG_DIR/ /

RUN wget -qO- https://gitlab.alpinelinux.org/alpine/aports/-/raw/89dc4b937a7591002c9f8d437d0efe4eabaeea99/community/xrdp/xrdp.post-install | sh

ENV TZ=UTC

COPY rootfs /

EXPOSE 3389

CMD ["/usr/bin/start.sh"]
