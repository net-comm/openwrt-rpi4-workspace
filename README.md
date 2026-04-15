# OpenWrt Raspberry Pi 4 Workspace

A build workspace for [OpenWrt](https://openwrt.org/) images targeting **Raspberry Pi 4** (Broadcom BCM2711, ARM Cortex-A72). This repository pulls custom packages from the [x86_64 workspace](https://github.com/net-comm/openwrt-x86_64-workspace) via a git submodule and provides RPi4-specific build configuration.

## What's included

All custom packages come from the upstream x86_64 workspace (via the `upstream/` submodule):

- **luci-theme-netcomm** — NetComm-inspired LuCI theme
- **luci-app-watchdog** — Connectivity watchdog
- **luci-app-congestion-monitor** — WAN congestion monitor
- **luci-app-intruder-alert** — Intruder alert system
- **rest-api-app** — REST API

This repo adds RPi4-specific configuration:

- `.config` — Build config targeting `bcm27xx/bcm2711` with onboard WiFi, USB 3.0, and USB Ethernet drivers
- `Dockerfile` — Docker-based build for RPi4
- `build.sh` — One-command Docker build
- `flash-sd.sh` — Write firmware to SD card
- `.github/workflows/build.yml` — GitHub Actions CI

---

## Quick start

### Clone (with submodule)

```bash
git clone --recurse-submodules https://github.com/net-comm/openwrt-rpi4-workspace.git
cd openwrt-rpi4-workspace
```

### Build with Docker

```bash
./build.sh
```

Firmware images appear in `./output/`.

### Build with GitHub Actions

1. Go to **Actions** → **OpenWrt Raspberry Pi 4 Build**
2. Click **Run workflow**
3. Download the `openwrt-rpi4-images` artifact when complete

### Flash to SD card

```bash
gunzip output/openwrt-bcm27xx-bcm2711-rpi-4-ext4-factory.img.gz
sudo ./flash-sd.sh output/openwrt-bcm27xx-bcm2711-rpi-4-ext4-factory.img /dev/sdX
```

Insert the SD card into your Raspberry Pi 4 and power on. LuCI will be available at **http://192.168.1.1**.

---

## Updating the upstream packages

```bash
cd upstream
git pull origin main
cd ..
git add upstream
git commit -m "Update upstream workspace"
```

---

## RPi4-specific configuration

The `.config` targets `bcm27xx/bcm2711` and includes:

| Feature | Config |
|---------|--------|
| Target | `CONFIG_TARGET_bcm27xx_bcm2711_DEVICE_rpi-4=y` |
| Onboard WiFi | `kmod-brcmfmac` + `brcmfmac-firmware-43455-sdio` |
| USB 3.0 | `kmod-usb3` |
| USB Ethernet | `kmod-usb-net-asix`, `kmod-usb-net-rtl8152` |
| Filesystem | ext4 (easy to resize) |

To customise further, clone the OpenWrt source and run `make menuconfig`, then copy the resulting `.config` back here.
