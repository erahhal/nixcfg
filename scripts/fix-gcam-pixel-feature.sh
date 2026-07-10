#!/usr/bin/env bash
#
# fix-gcam-pixel-feature.sh
#
# Adds the com.google.android.feature.PIXEL_2019_EXPERIENCE system feature to
# an Android device. Certain GCam mods (including the BSG "aweme" build used
# here) route the power-button STILL_IMAGE_CAMERA intent through
# CameraImageActivity, which checks for this Pixel feature before initializing
# its device config; without it the activity can NPE on launch.
#
# INSTALL METHOD -- Magisk module (persistent):
#   The device (OnePlus 13, OxygenOS 16) mounts / read-only under dm-verity, so
#   the old "mount -o remount,rw / && write /system/etc/sysconfig/..." approach
#   does NOT persist -- the file is gone after the next reboot/OTA. Verified
#   on-device that the feature was absent despite that method having been "run"
#   before. Instead we install a Magisk module that magic-mounts the sysconfig
#   file into /system on every boot, which survives reboots (and OTAs, as long
#   as Magisk is re-flashed after a major OS upgrade).
#
#   For non-Magisk rooted devices with a writable /system, pass --direct to use
#   the legacy in-place write instead.
#
# NOTE ON THE POWER-BUTTON CAMERA FACING:
#   This feature prevents the launch CRASH, but it does NOT change which camera
#   the power button opens. On this build, an UNLOCKED power double-tap sends
#   STILL_IMAGE_CAMERA (-> CameraImageActivity, which opens FRONT-facing), while
#   a LOCKED double-tap sends STILL_IMAGE_CAMERA_SECURE (-> SecureCameraActivity,
#   which opens the REAR camera correctly). That front-facing launch when
#   unlocked is an app-level behavior with no safe shared_prefs override -- see
#   bsg-gcam-oneplus13-config.xml notes. This script does not attempt to fix it.
#
# Requirements:
#   - ADB installed and device connected via USB
#   - Root: Magisk (default), or a rooted device with writable /system (--direct)
#   - A reboot is required after running this script

set -euo pipefail

FEATURE_NAME="com.google.android.feature.PIXEL_2019_EXPERIENCE"
MODULE_ID="gcam_pixel_feature"
MODULE_DIR="/data/adb/modules/${MODULE_ID}"
SYSCONFIG_REL="system/etc/sysconfig/pixel_experience_2019.xml"
SYSCONFIG_DIRECT="/system/etc/sysconfig/pixel_experience_2019.xml"

MODE="magisk"
for arg in "$@"; do
    case "$arg" in
        --direct) MODE="direct" ;;
        -h|--help) sed -n '3,40p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

echo "=== GCam Pixel Feature Fix ==="
echo ""

if ! command -v adb &>/dev/null; then
    echo "ERROR: adb not found. Install Android platform-tools first."
    exit 1
fi
if ! adb get-state &>/dev/null 2>&1; then
    echo "ERROR: No device connected. Connect via USB and enable USB debugging."
    exit 1
fi
echo "Device connected: $(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
echo ""

# Already present?
if adb shell "pm list features" 2>/dev/null | grep -q "$FEATURE_NAME"; then
    echo "Feature '$FEATURE_NAME' is already present. Nothing to do."
    exit 0
fi

# Confirm root via su (works with Magisk).
if ! adb shell "su -c 'id'" 2>/dev/null | grep -q "uid=0"; then
    echo "ERROR: root not available via 'su'. Ensure the device is rooted"
    echo "       (Magisk) and root access is granted to shell."
    exit 1
fi

FEATURE_XML='<?xml version="1.0" encoding="utf-8"?>
<config>
    <feature name="com.google.android.feature.PIXEL_2019_EXPERIENCE" />
</config>'

if [[ "$MODE" == "magisk" ]]; then
    # Sanity: is this actually a Magisk device?
    if ! adb shell "su -c 'test -d /data/adb/modules'" </dev/null 2>/dev/null; then
        echo "ERROR: /data/adb/modules not found -- this does not look like a"
        echo "       Magisk device. For a non-Magisk rooted device with a"
        echo "       writable /system, re-run with --direct."
        exit 1
    fi

    echo "Installing Magisk module '$MODULE_ID'..."
    adb shell "su -c 'mkdir -p ${MODULE_DIR}/system/etc/sysconfig'" </dev/null

    adb shell "su -c 'cat > ${MODULE_DIR}/module.prop'" <<EOF
id=${MODULE_ID}
name=GCam Pixel 2019 Feature
version=v1
versionCode=1
author=nixcfg
description=Adds ${FEATURE_NAME} so GCam CameraImageActivity (power-button STILL_IMAGE_CAMERA) initializes without crashing.
EOF

    echo "$FEATURE_XML" | adb shell "su -c 'cat > ${MODULE_DIR}/${SYSCONFIG_REL}'"

    if ! adb shell "su -c 'grep -q PIXEL_2019_EXPERIENCE ${MODULE_DIR}/${SYSCONFIG_REL}'" </dev/null 2>/dev/null; then
        echo "ERROR: failed to write module sysconfig file."
        exit 1
    fi
    echo "Module installed at ${MODULE_DIR} (activates on next boot)."
else
    echo "Installing directly into /system (legacy, non-persistent on dm-verity)..."
    adb root 2>/dev/null || true
    sleep 2; adb wait-for-device
    adb shell "mount -o remount,rw /" 2>/dev/null || \
        adb shell "su -c 'mount -o remount,rw /'" 2>/dev/null || true
    echo "$FEATURE_XML" | adb shell "su -c 'cat > ${SYSCONFIG_DIRECT}'"
    if ! adb shell "su -c 'grep -q PIXEL_2019_EXPERIENCE ${SYSCONFIG_DIRECT}'" </dev/null 2>/dev/null; then
        echo "ERROR: failed to write ${SYSCONFIG_DIRECT}."
        exit 1
    fi
    echo "Wrote ${SYSCONFIG_DIRECT}."
fi

echo ""
read -rp "Reboot device now? (Y/n) " answer
if [[ ! "$answer" =~ ^[Nn]$ ]]; then
    echo "Rebooting..."
    adb reboot
    echo "Waiting for device..."
    adb wait-for-device
    for _ in $(seq 1 30); do
        [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]] && break
        sleep 3
    done
    if adb shell "pm list features" 2>/dev/null | grep -q "$FEATURE_NAME"; then
        echo "Done! Feature is active."
    else
        echo "Device is back but feature not detected yet -- give it a moment,"
        echo "or re-check with: adb shell pm list features | grep PIXEL_2019"
    fi
else
    echo "Please reboot the device manually for the change to take effect."
fi
