#!/bin/sh
# build.sh — Build OpenWrt Raspberry Pi 4 firmware inside Docker.
#
# Usage:
#   ./build.sh [--tag IMAGE_TAG] [--output OUTPUT_DIR]
#
# Defaults:
#   IMAGE_TAG  = openwrt-rpi4-build
#   OUTPUT_DIR = ./output
#
# The built firmware images (*.img.gz) are copied to OUTPUT_DIR.
# A first build takes 60–90 minutes; subsequent builds are faster because
# Docker caches the OpenWrt clone and feed-install layers.
#
# Requirements:
#   Docker 20.10+ installed and the daemon running.

set -eu

# ── Defaults ──────────────────────────────────────────────────────────────────
IMAGE_TAG="openwrt-rpi4-build"
OUTPUT_DIR="$(dirname "$0")/output"

# ── Argument parsing ──────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
    case "$1" in
        --tag)    IMAGE_TAG="$2";   shift 2 ;;
        --output) OUTPUT_DIR="$2";  shift 2 ;;
        -h|--help)
            sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Check Docker is available ─────────────────────────────────────────────────
if ! command -v docker > /dev/null 2>&1; then
    echo "ERROR: docker not found in PATH." >&2
    echo "Install Docker: https://docs.docker.com/engine/install/" >&2
    exit 1
fi

# ── Build the Docker image ────────────────────────────────────────────────────
echo "=== Building Docker image: ${IMAGE_TAG} ==="
docker build --tag "${IMAGE_TAG}" "${WORKSPACE_DIR}"

# ── Extract firmware images ───────────────────────────────────────────────────
echo ""
echo "=== Extracting firmware images to: ${OUTPUT_DIR} ==="
mkdir -p "${OUTPUT_DIR}"

CONTAINER=$(docker create "${IMAGE_TAG}")
docker cp "${CONTAINER}:/build/openwrt/bin/targets/bcm27xx/bcm2711/." "${OUTPUT_DIR}/"
docker rm "${CONTAINER}" > /dev/null

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Build complete! Firmware images ==="
ls -lh "${OUTPUT_DIR}"/*.img.gz 2>/dev/null || \
    echo "(No *.img.gz files found — check ${OUTPUT_DIR} for other output)"
echo ""
echo "To flash to SD card:"
echo "  gunzip ${OUTPUT_DIR}/openwrt-bcm27xx-bcm2711-rpi-4-ext4-factory.img.gz"
echo "  sudo ./flash-sd.sh ${OUTPUT_DIR}/openwrt-bcm27xx-bcm2711-rpi-4-ext4-factory.img /dev/sdX"
