# syntax=docker/dockerfile:1
#
# OpenWrt Raspberry Pi 4 build image
#
# Builds OpenWrt v23.05.5 for bcm27xx/bcm2711 (Raspberry Pi 4) with all
# custom packages from the upstream workspace baked in.  The resulting image
# contains the compiled firmware under
#   /build/openwrt/bin/targets/bcm27xx/bcm2711/
#
# Typical usage:
#   docker build -t openwrt-rpi4 .
#   docker create --name owrt-out openwrt-rpi4
#   docker cp owrt-out:/build/openwrt/bin/targets/bcm27xx/bcm2711/. ./output/
#   docker rm owrt-out
#
# Or simply run:
#   ./build.sh

FROM ubuntu:20.04

ARG OPENWRT_TAG=v23.05.5

ENV DEBIAN_FRONTEND=noninteractive \
    FORCE_UNSAFE_CONFIGURE=1

# ── Build dependencies ────────────────────────────────────────────────────────
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        build-essential clang flex bison g++ gawk \
        gettext git libncurses-dev \
        libssl-dev python3-setuptools rsync unzip zlib1g-dev \
        file wget texinfo libelf-dev libzstd-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# ── Clone OpenWrt source (layer cached until OPENWRT_TAG changes) ─────────────
RUN git clone --depth 1 --branch "${OPENWRT_TAG}" \
        https://github.com/openwrt/openwrt.git openwrt

# ── Update & install feeds (layer cached alongside OpenWrt clone) ─────────────
RUN cd openwrt && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a

# ── Copy workspace into the image ─────────────────────────────────────────────
COPY . /build/workspace

# ── Inject custom packages and filesystem overlay from upstream submodule ─────
RUN cp -r /build/workspace/upstream/luci-theme-netcomm            openwrt/package/luci-theme-netcomm && \
    cp -r /build/workspace/upstream/luci-app-watchdog             openwrt/package/luci-app-watchdog && \
    cp -r /build/workspace/upstream/luci-app-congestion-monitor   openwrt/package/luci-app-congestion-monitor && \
    cp -r /build/workspace/upstream/luci-app-intruder-alert       openwrt/package/luci-app-intruder-alert && \
    cp -r /build/workspace/upstream/rest-api-app                  openwrt/package/rest-api-app && \
    cp -r /build/workspace/upstream/files/.                       openwrt/files/

# ── Apply build config and expand defaults ────────────────────────────────────
RUN cp /build/workspace/.config openwrt/.config && \
    cd openwrt && make defconfig

# ── Pre-fetch package sources ─────────────────────────────────────────────────
RUN cd openwrt && make download -j"$(nproc)"

# ── Full build ────────────────────────────────────────────────────────────────
RUN cd openwrt && \
    make -j"$(nproc)" 2>&1 | tee /build/build.log || \
    ( echo "=== Build failed — retrying single-threaded for verbose output ===" && \
      make -j1 V=s 2>&1 | tee /build/build-verbose.log; exit 1 )
