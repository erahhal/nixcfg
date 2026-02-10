#!/usr/bin/env bash
#
# install-gcam-config.sh
#
# Installs a BSG GCam config for the OnePlus 13 by merging it into the app's
# shared_prefs via ADB root. The config:
#   - Maps camera IDs: 2=Main (LYT-808), 3=UltraWide (JN5), 4=Tele 3x (LYT-600), 1=Front
#   - Disables EIS (software video stabilization) to avoid interfering with hardware OIS
#   - Spoofs Pixel 8 Pro for HDR+ processing
#   - Enables auxiliary cameras and lens toggles
#
# The OnePlus 13's main and telephoto cameras have firmware-level OIS that is
# always active and not controllable via Camera2 API. GCam's EIS would add
# software stabilization on top, causing frame cropping and jello artifacts.
#
# Usage:
#   install-gcam-config.sh [--user <id>] [--all]
#
#   --user <id>   Install for a specific Android user ID only
#
#   By default, installs for all users that have the app's data directory.
#
# Requirements:
#   - ADB installed and device connected via USB
#   - Root access on device (su must work via adb shell)
#   - BSG GCam MGC 9.6.080 V17 installed (package: com.ss.android.ugc.aweme)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/bsg-gcam-oneplus13-config.xml"
PACKAGE="com.ss.android.ugc.aweme"
PREFS_FILENAME="${PACKAGE}_preferences.xml"
ACTIVITY="$PACKAGE/com.google.android.apps.camera.legacy.app.activity.main.CameraActivity"

# Parse arguments
TARGET_USER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
            TARGET_USER="$2"
            shift 2
            ;;
        --all)
            # Kept for backwards compatibility; this is now the default
            shift
            ;;
        -h|--help)
            head -24 "$0" | tail -19
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--user <id>] [--all]"
            exit 1
            ;;
    esac
done

echo "=== BSG GCam Config Installer (OnePlus 13) ==="
echo ""

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

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

DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
echo "Device connected: $DEVICE_MODEL"

# Check root access
if ! adb shell "su -c 'id'" 2>/dev/null | grep -q "uid=0"; then
    echo ""
    echo "ERROR: Root access not available via 'su'."
    echo "Ensure your device is rooted and su is accessible via adb shell."
    exit 1
fi

# Check GCam is installed
if ! adb shell "pm list packages" 2>/dev/null | grep -q "$PACKAGE"; then
    echo ""
    echo "ERROR: BSG GCam ($PACKAGE) is not installed."
    exit 1
fi

echo "GCam package found: $PACKAGE"

# Discover all users and which have the app's data directory
echo ""
echo "Scanning users..."
ALL_USER_IDS=()
USERS_WITH_DATA=()
declare -A USER_NAMES
declare -A USER_HAS_PREFS

while IFS= read -r line; do
    user_id=$(echo "$line" | grep -oP 'UserInfo\{\K[0-9]+')
    user_name=$(echo "$line" | grep -oP 'UserInfo\{[0-9]+:\K[^:]+')
    ALL_USER_IDS+=("$user_id")
    USER_NAMES[$user_id]="$user_name"

    app_data_dir="/data/user/$user_id/$PACKAGE"
    prefs_path="$app_data_dir/shared_prefs/$PREFS_FILENAME"

    # Note: adb shell reads stdin, so redirect </dev/null to prevent it from
    # consuming the remaining lines of the while-read loop.
    if adb shell "su -c 'test -d $app_data_dir'" </dev/null 2>/dev/null; then
        USERS_WITH_DATA+=("$user_id")
        if adb shell "su -c 'test -f $prefs_path'" </dev/null 2>/dev/null; then
            USER_HAS_PREFS[$user_id]=true
            echo "  User $user_id ($user_name): app data found, prefs exist"
        else
            USER_HAS_PREFS[$user_id]=false
            echo "  User $user_id ($user_name): app data found, no prefs yet (fresh install)"
        fi
    else
        echo "  User $user_id ($user_name): app not installed for this user"
    fi
done < <(adb shell "pm list users" </dev/null 2>/dev/null | grep "UserInfo")

if [[ ${#USERS_WITH_DATA[@]} -eq 0 ]]; then
    echo ""
    echo "ERROR: No users have GCam app data."
    exit 1
fi

# Determine which users to install for
INSTALL_USERS=()
if [[ -n "$TARGET_USER" ]]; then
    app_data_dir="/data/user/$TARGET_USER/$PACKAGE"
    if ! adb shell "su -c 'test -d $app_data_dir'" 2>/dev/null; then
        echo ""
        echo "ERROR: User $TARGET_USER does not have GCam app data."
        exit 1
    fi
    INSTALL_USERS=("$TARGET_USER")
else
    # Default: all users with app data
    INSTALL_USERS=("${USERS_WITH_DATA[@]}")
fi

echo ""
echo "Will install for user(s): ${INSTALL_USERS[*]}"

# Force-stop GCam and confirm it's dead
echo ""
echo "Stopping GCam..."
adb shell "am force-stop $PACKAGE"
sleep 1
if adb shell "pidof $PACKAGE" &>/dev/null; then
    echo "WARNING: GCam process still running, killing..."
    adb shell "su -c 'kill -9 \$(pidof $PACKAGE)'" 2>/dev/null || true
    sleep 1
fi

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

install_for_user() {
    local user_id="$1"
    local app_data_dir="/data/user/$user_id/$PACKAGE"
    local prefs_dir="$app_data_dir/shared_prefs"
    local prefs_path="$prefs_dir/$PREFS_FILENAME"

    echo ""
    echo "--- User $user_id (${USER_NAMES[$user_id]:-unknown}) ---"

    # Determine the app's UID from the data directory
    local app_owner
    app_owner=$(adb shell "su -c 'stat -c %U:%G $app_data_dir'" 2>/dev/null | tr -d '\r')
    if [[ -z "$app_owner" || "$app_owner" == *"No such file"* ]]; then
        echo "  ERROR: Cannot determine app owner. Skipping."
        return 1
    fi
    local app_uid="${app_owner%%:*}"
    echo "  App owner: $app_owner"

    local output_file="$TMPDIR/output_prefs_$user_id.xml"

    if [[ "${USER_HAS_PREFS[$user_id]:-false}" == true ]]; then
        # Existing prefs: merge config into them
        echo "  Pulling current preferences..."
        adb shell "su -c 'cat $prefs_path'" > "$TMPDIR/current_prefs_$user_id.xml"

        echo "  Merging config into existing preferences..."
        python3 - "$TMPDIR/current_prefs_$user_id.xml" "$CONFIG_FILE" "$output_file" <<'PYEOF'
import xml.etree.ElementTree as ET
import sys

def merge_prefs(existing_path, config_path, output_path):
    existing_tree = ET.parse(existing_path)
    config_tree = ET.parse(config_path)
    existing_root = existing_tree.getroot()
    config_root = config_tree.getroot()

    existing_map = {}
    for elem in list(existing_root):
        name = elem.get('name')
        if name is not None:
            existing_map[(elem.tag, name)] = elem

    added = replaced = 0
    for elem in config_root:
        if not isinstance(elem.tag, str):
            continue
        name = elem.get('name')
        if name is None:
            continue
        key = (elem.tag, name)
        if key in existing_map:
            old = existing_map[key]
            idx = list(existing_root).index(old)
            existing_root.remove(old)
            existing_root.insert(idx, elem)
            replaced += 1
        else:
            existing_root.append(elem)
            added += 1

    existing_tree.write(output_path, encoding='utf-8', xml_declaration=True)

    with open(output_path, 'r') as f:
        content = f.read()
    content = content.replace(
        "<?xml version='1.0' encoding='utf-8'?>",
        "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>")
    with open(output_path, 'w') as f:
        f.write(content)

    print(f"    {added} settings added, {replaced} settings replaced")

merge_prefs(sys.argv[1], sys.argv[2], sys.argv[3])
PYEOF
    else
        # No existing prefs: use config as fresh prefs file
        echo "  No existing preferences, writing fresh config..."
        cp "$CONFIG_FILE" "$output_file"
    fi

    # Ensure shared_prefs directory exists with correct ownership
    adb shell "su -c 'mkdir -p $prefs_dir && chown $app_uid:$app_uid $prefs_dir && chmod 771 $prefs_dir'"

    # Push prefs to device
    echo "  Pushing preferences..."
    local staging="/sdcard/Download/.gcam_prefs_staging.xml"
    adb push "$output_file" "$staging" > /dev/null
    adb shell "su -c 'cat $staging > $prefs_path && chmod 660 $prefs_path && chown $app_owner $prefs_path && rm $staging'"

    # Verify key settings
    echo "  Verifying..."
    local verify
    verify=$(adb shell "su -c 'cat $prefs_path'" 2>/dev/null)

    local all_ok=true
    check_setting() {
        local pattern="$1"
        local label="$2"
        if echo "$verify" | grep -q "$pattern"; then
            echo "    OK  $label"
        else
            echo "    FAIL  $label"
            all_ok=false
        fi
    }

    check_setting 'name="pref_video_stabilization_key">0<'      "EIS disabled"
    check_setting 'name="pref_ois_key">1<'                       "OIS enabled"
    check_setting 'name="device_key">husky<'                      "Pixel 8 Pro spoof"
    check_setting 'name="device_hdrplus_key_1">blueline<'         "HDR+ model (blueline)"
    check_setting 'name="pref_camera_id_list_key"'                "Camera ID mapping"
    check_setting 'name="pref_lens_title_key_0">Main<'            "Lens labels"
    check_setting 'name="pref_aux_key">1<'                        "AUX cameras"
    check_setting 'name="lib_skipmetadatacheck_key_p0_0">1<'      "Metadata check skip"

    if [[ "$all_ok" == false ]]; then
        return 1
    fi
}

# Install for each target user
FAILURES=0
for uid in "${INSTALL_USERS[@]}"; do
    if ! install_for_user "$uid"; then
        ((FAILURES++)) || true
    fi
done

echo ""
if [[ $FAILURES -gt 0 ]]; then
    echo "WARNING: $FAILURES user(s) had failures. Check output above."
else
    echo "All users configured successfully."
fi

# Run fix-gcam-pixel-feature.sh to ensure Pixel feature flag is present
PIXEL_FIX_SCRIPT="$SCRIPT_DIR/fix-gcam-pixel-feature.sh"
if [[ -x "$PIXEL_FIX_SCRIPT" ]]; then
    echo ""
    echo "=== Running Pixel feature fix ==="
    "$PIXEL_FIX_SCRIPT"
else
    echo ""
    echo "WARNING: $PIXEL_FIX_SCRIPT not found or not executable. Skipping Pixel feature fix."
fi

# Launch GCam
echo ""
read -rp "Launch GCam now? (Y/n) " answer
if [[ ! "$answer" =~ ^[Nn]$ ]]; then
    echo "Launching GCam..."
    adb shell "am start -n $ACTIVITY" > /dev/null 2>&1
    echo "Done. Check that all lenses work and video stabilization is off."
else
    echo "Done. Launch GCam manually to apply the settings."
fi
