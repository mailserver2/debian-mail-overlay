FROM debian:13-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_CORES

ARG SKALIBS_VER=2.14.5.0
ARG EXECLINE_VER=2.9.8.0
ARG S6_VER=2.14.0.0
ARG RSPAMD_VER=3.14.2
ARG GUCCI_VER=v1.9.0
ARG TCD_VER=v2.10.0

ARG SKALIBS_SHA256_HASH="d8d9ec756b112ab6d4a9896ba0f53aca92559bc90aeaccd53ed8177e6e159764"
ARG EXECLINE_SHA256_HASH="d05e0b75cc21841692119c7a7838163acd7f05318bd69e779068266daa7ce91f"
ARG S6_SHA256_HASH="586bf8474d852655b89f1144c3d95461a1cee77f016dae6e75a3328b8a2f5df6"
ARG RSPAMD_SHA256_HASH="b8402b639b2480b793795907d53609f375fd19b99501f777ff49f2e410edfb5b"
ARG GUCCI_SHA256_HASH="5230c34e6cc39e95edd903b38a7466a1bbe0fb87955d572d4af7d9226077dd4c"
ARG TCD_SHA256_HASH="b0c65a9bf5996e05bd0db9ead202476951b86f16c2e34e195c0b968f938613c1"

LABEL description="s6 + rspamd image based on Debian" \
      maintainer="Hardware <contact@meshup.net>" \
      rspamd_version="Rspamd v$RSPAMD_VER built from source" \
      s6_version="s6 v$S6_VER built from source"

ENV LC_ALL=C

RUN NB_CORES=${BUILD_CORES-$(getconf _NPROCESSORS_CONF)} \
    && BUILD_DEPS=" \
    cmake \
    gcc \
    g++ \
    make \
    ragel \
    wget \
    pkg-config \
    libarchive-dev \
    liblua5.4-dev \
    libluajit-5.1-dev \
    libglib2.0-dev \
    libevent-dev \
    libsqlite3-dev \
    libicu-dev \
    libssl-dev \
    libhyperscan-dev \
    libjemalloc-dev \
    libmagic-dev \
    libsodium-dev" \
 && apt-get update && apt-get dist-upgrade -y \
 && apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    libarchive13t64 \
    libevent-2.1-7t64 \
    libglib2.0-0 \
    libssl3t64 \
    libmagic1t64 \
    liblua5.4-0 \
    libluajit-5.1-2 \
    libsqlite3-0 \
    libhyperscan5 \
    libjemalloc2 \
    libsodium23 \
    sqlite3 \
    openssl \
    ca-certificates \
    gnupg \
    dirmngr \
    netcat-openbsd \
 && cd /tmp \
 && SKALIBS_TARBALL="skalibs-${SKALIBS_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/skalibs/${SKALIBS_TARBALL} \
 && CHECKSUM=$(sha256sum ${SKALIBS_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SKALIBS_SHA256_HASH}" ]; then echo "${SKALIBS_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${SKALIBS_TARBALL} && cd skalibs-${SKALIBS_VER} \
 && ./configure --prefix=/usr --datadir=/etc \
 && make && make install \
 && cd /tmp \
 && EXECLINE_TARBALL="execline-${EXECLINE_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/execline/${EXECLINE_TARBALL} \
 && CHECKSUM=$(sha256sum ${EXECLINE_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${EXECLINE_SHA256_HASH}" ]; then echo "${EXECLINE_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${EXECLINE_TARBALL} && cd execline-${EXECLINE_VER} \
 && ./configure --prefix=/usr --libdir=/usr/local/lib/ \
 && make && make install \
 && cd /tmp \
 && S6_TARBALL="s6-${S6_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/s6/${S6_TARBALL} \
 && CHECKSUM=$(sha256sum ${S6_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${S6_SHA256_HASH}" ]; then echo "${S6_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${S6_TARBALL} && cd s6-${S6_VER} \
 && ./configure --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
 && make && make install \
 && cd /tmp \
 && RSPAMD_TARBALL="${RSPAMD_VER}.tar.gz" \
 && wget -q https://github.com/rspamd/rspamd/archive/${RSPAMD_TARBALL} \
 && CHECKSUM=$(sha256sum ${RSPAMD_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${RSPAMD_SHA256_HASH}" ]; then echo "${RSPAMD_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${RSPAMD_TARBALL} && cd rspamd-${RSPAMD_VER} \
 && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCONFDIR=/etc/rspamd \
    -DRUNDIR=/run/rspamd \
    -DDBDIR=/var/mail/rspamd \
    -DLOGDIR=/var/log/rspamd \
    -DPLUGINSDIR=/usr/share/rspamd \
    -DLIBDIR=/usr/lib/rspamd \
    -DNO_SHARED=ON \
    -DWANT_SYSTEMD_UNITS=OFF \
    -DENABLE_TORCH=ON \
    -DENABLE_HIREDIS=ON \
    -DINSTALL_WEBUI=ON \
    -DENABLE_OPTIMIZATION=ON \
    -DENABLE_HYPERSCAN=ON \
    -DENABLE_JEMALLOC=ON \
    -DJEMALLOC_ROOT_DIR=/jemalloc \
    . \
 && make -j${NB_CORES} \
 && make install \
 && cd /tmp \
 && GUCCI_BINARY="gucci-${GUCCI_VER}-linux-amd64" \
 && wget -q https://github.com/noqcks/gucci/releases/download/${GUCCI_VER}/${GUCCI_BINARY} \
 && CHECKSUM=$(sha256sum ${GUCCI_BINARY} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${GUCCI_SHA256_HASH}" ]; then echo "${GUCCI_BINARY} : bad checksum" && exit 1; fi \
 && chmod +x ${GUCCI_BINARY} \
 && mv ${GUCCI_BINARY} /usr/local/bin/gucci \
 && TCD_TARBALL="traefik-certs-dumper_${TCD_VER}_linux_amd64.tar.gz" \
 && wget -q https://github.com/ldez/traefik-certs-dumper/releases/download/${TCD_VER}/${TCD_TARBALL} \
 && CHECKSUM=$(sha256sum ${TCD_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${TCD_SHA256_HASH}" ]; then echo "${TCD_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${TCD_TARBALL} \
 && mv traefik-certs-dumper /usr/local/bin/traefik-certs-dumper \
 && chmod +x /usr/local/bin/traefik-certs-dumper \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old
