FROM debian:11.6-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_CORES

ARG SKALIBS_VER=2.13.1.0
ARG EXECLINE_VER=2.9.2.1
ARG S6_VER=2.11.3.0
ARG RSPAMD_VER=3.4
ARG GUCCI_VER=1.6.6

ARG SKALIBS_SHA256_HASH="b3c48938c7fba4b19a8b0dce6e7a11427717a0901160bb62cfc6823f8ac86d92"
ARG EXECLINE_SHA256_HASH="dbccdd95bcee4b33d4d4cb7544ab92903ba2e2764165ddc8f395b67755b20405"
ARG S6_SHA256_HASH="0ef2de80c40b603d58bf65ec5dd9f0bb1f227d35f311e8948d9e30f81efb5b81"
ARG RSPAMD_SHA256_HASH="f8d3e2b9a1a6ed6521c60fe505e97086624407f67366f0ce882eee433a53c355"
ARG GUCCI_SHA256_HASH="c1a25f73e91879a744b630d0922899a8ece0ea93567d689727e2184bc888a6db"

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
    liblua5.1-0-dev \
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
    libevent-2.1-7 \
    libglib2.0-0 \
    libssl1.1 \
    libmagic1 \
    liblua5.1-0 \
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
    netcat \
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
 && GUCCI_BINARY="gucci-v${GUCCI_VER}-linux-amd64" \
 && wget -q https://github.com/noqcks/gucci/releases/download/${GUCCI_VER}/${GUCCI_BINARY} \
 && CHECKSUM=$(sha256sum ${GUCCI_BINARY} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${GUCCI_SHA256_HASH}" ]; then echo "${GUCCI_BINARY} : bad checksum" && exit 1; fi \
 && chmod +x ${GUCCI_BINARY} \
 && mv ${GUCCI_BINARY} /usr/local/bin/gucci \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old
