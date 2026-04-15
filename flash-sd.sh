#!/bin/sh
# flash-sd.sh — Write an OpenWrt image to an SD card for Raspberry Pi 4.
#
# Usage:
#   sudo ./flash-sd.sh <image-file> <device>
#
# Example:
#   sudo ./flash-sd.sh output/openwrt-bcm27xx-bcm2711-rpi-4-ext4-factory.img /dev/sdb
#
# WARNING: This will overwrite ALL data on the target device.
#          Double-check the device path before running!

set -eu

if [ $# -lt 2 ]; then
    echo "Usage: sudo $0 <image-file> <device>"
    echo "Example: sudo $0 openwrt-bcm27xx-bcm2711-rpi-4-ext4-factory.img /dev/sdb"
    exit 1
fi

IMAGE="$1"
DEVICE="$2"

if [ ! -f "$IMAGE" ]; then
    echo "ERROR: Image not found: $IMAGE"
    echo "If the image is gzipped, decompress it first:"
    echo "  gunzip ${IMAGE}.gz"
    exit 1
fi

if [ ! -b "$DEVICE" ]; then
    echo "ERROR: $DEVICE is not a block device."
    echo "Use 'lsblk' to find your SD card device (e.g., /dev/sdb)."
    exit 1
fi

# Safety check: refuse to write to mounted devices
if mount | grep -q "^${DEVICE}"; then
    echo "ERROR: $DEVICE (or a partition on it) is currently mounted."
    echo "Unmount it first:  sudo umount ${DEVICE}*"
    exit 1
fi

echo "============================================"
echo "  Image:  $IMAGE"
echo "  Device: $DEVICE"
echo "============================================"
echo ""
echo "WARNING: ALL data on $DEVICE will be destroyed!"
printf "Continue? [y/N] "
read -r REPLY
case "$REPLY" in
    y|Y) ;;
    *)   echo "Aborted."; exit 0 ;;
esac

echo ""
echo "Writing image to $DEVICE ..."
dd if="$IMAGE" of="$DEVICE" bs=4M status=progress conv=fsync

echo ""
echo "Syncing ..."
sync

echo ""
echo "Done! Insert the SD card into your Raspberry Pi 4 and power it on."
echo "LuCI will be available at http://192.168.1.1 once booted."
