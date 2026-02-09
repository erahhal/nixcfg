#!/usr/bin/env bash
#
# fix-gcam-pixel-feature.sh
#
# Adds the com.google.android.feature.PIXEL_2019_EXPERIENCE system feature
# to an Android device. This is required by certain GCam mods that crash on
# non-Pixel devices when launched via the STILL_IMAGE_CAMERA intent (e.g.,
# power button double-tap camera shortcut).
#
# The crash occurs because the GCam mod's CameraImageActivity checks for
# this Pixel feature flag before initializing its device config, and skips
# initialization when the feature is absent, leading to a NullPointerException.
#
# Requirements:
#   - ADB installed and device connected via USB
#   - ADB root access enabled on the device:
#     Settings -> System -> Developer options -> "Root access" or "Rooted debugging"
#     (must be set to "ADB only" or "Apps and ADB")
#   - A reboot is required after running this script

set -euo pipefail

FEATURE_NAME="com.google.android.feature.PIXEL_2019_EXPERIENCE"
SYSCONFIG_PATH="/system/etc/sysconfig/pixel_experience_2019.xml"

echo "=== GCam Pixel Feature Fix ==="
echo ""

# Check adb is available
if ! command -v adb &>/dev/null; then
    echo "ERROR: adb not found. Install Android platform-tools first."
    exit 1
fi

# Check device is connected
if ! adb get-state &>/dev/null 2>&1; then
    echo "ERROR: No device connected. Connect your device via USB and enable USB debugging."
    exit 1
fi

echo "Device connected: $(adb shell getprop ro.product.model 2>/dev/null)"
echo ""

# Check if feature already exists
if adb shell pm list features 2>/dev/null | grep -q "$FEATURE_NAME"; then
    echo "Feature '$FEATURE_NAME' is already present. Nothing to do."
    exit 0
fi

# Try to enable root
echo "Enabling ADB root access..."
root_output=$(adb root 2>&1)
if echo "$root_output" | grep -qi "disabled\|cannot\|denied\|error"; then
    echo ""
    echo "ERROR: ADB root access is not enabled."
    echo ""
    echo "To enable it:"
    echo "  1. Open Settings on your phone"
    echo "  2. Go to System -> Developer options"
    echo "  3. Find 'Root access' (or 'Rooted debugging')"
    echo "  4. Set it to 'ADB only' or 'Apps and ADB'"
    echo "  5. Re-run this script"
    exit 1
fi

# Wait a moment for root to take effect (adb restarts)
sleep 2
adb wait-for-device

# Remount filesystem as read-write
echo "Remounting filesystem..."
adb shell "mount -o remount,rw /" 2>/dev/null || true

# Write the feature config file
echo "Writing feature config to $SYSCONFIG_PATH..."
adb shell "cat > $SYSCONFIG_PATH" <<'XMLEOF'
<?xml version="1.0" encoding="utf-8"?>
<config>
    <feature name="com.google.android.feature.PIXEL_2019_EXPERIENCE" />
</config>
XMLEOF

# Verify
if adb shell "cat $SYSCONFIG_PATH" 2>/dev/null | grep -q "$FEATURE_NAME"; then
    echo "Feature config written successfully."
else
    echo "ERROR: Failed to write feature config."
    exit 1
fi

echo ""
read -rp "Reboot device now? (y/N) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    adb reboot
    echo "Waiting for device..."
    adb wait-for-device
    sleep 15
    if adb shell pm list features 2>/dev/null | grep -q "$FEATURE_NAME"; then
        echo "Done! Feature is active. GCam power-button shortcut should now work."
    else
        echo "Device is back but feature not detected yet. It may need more time to boot."
    fi
else
    echo "Please reboot the device manually for the change to take effect."
fi
