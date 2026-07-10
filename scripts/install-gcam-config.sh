#!/usr/bin/env bash
#
# install-gcam-config.sh
#
# Installs a BSG GCam config for the OnePlus 13 by merging it into the app's
# shared_prefs via ADB root. The config:
#   - Maps camera IDs: 2=Main (LYT-808), 3=UltraWide (JN5), 4=Tele 3x (LYT-600), 1=Front
#   - Enables EIS (Camera2 mode 1) on top of HAL-driven OIS for video
#   - Spoofs Pixel 8 Pro for HDR+ processing
#   - Enables auxiliary cameras and lens toggles
#
# The OnePlus 13's main and telephoto cameras have firmware-level OIS that is
# auto-engaged by the HAL whenever a back camera is opened (verified live via
# `dumpsys media.camera`). The HAL advertises OIS as not API-controllable, so
# the BSG-side ois_api_supported / pref_ois_key flags are effectively no-ops
# for actually running OIS -- they only influence what BSG requests through
# the standard Camera2 API. EIS at Camera2 mode 1 layers on top to handle
# larger movement; the small viewfinder crop is the only side effect.
#
# The shipped config (bsg-gcam-oneplus13-config.xml) works for both BSG MGC
# 9.6.x and 9.7.x aweme builds - they share the same package name, prefs file,
# and BSG key schema. 9.7-only keys (merge, merge_processor, raw format,
# preview format, model) have safe "Auto" defaults on the OP13 and are left
# alone; change them via the in-app BSG module settings if needed.
#
# Usage:
#   install-gcam-config.sh [--user <id>] [--all] [--apk PATH] [--no-apk] [--reinstall]
#
#   --user <id>   Install config for a specific Android user ID only.
#   --apk PATH    Use a local APK file instead of downloading.
#   --no-apk      Skip the APK install/upgrade check entirely.
#   --reinstall   Reinstall the latest APK even if it is already installed.
#
#   By default, installs config for all users that have the app's data
#   directory. Also resolves the latest BSG MGC "aweme" build from
#   celsoazevedo.com (see "APK auto-tracking" below) and, if the device is not
#   already on it, downloads the APK (cached under ~/.cache/gcam-installer/) and
#   installs it via 'adb install -r'.
#
# Requirements:
#   - ADB installed and device connected via USB
#   - Root access on device (su must work via adb shell)
#   - curl on the host (only needed when resolving/downloading the APK)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/bsg-gcam-oneplus13-config.xml"
PACKAGE="com.ss.android.ugc.aweme"
PREFS_FILENAME="${PACKAGE}_preferences.xml"
# Launcher entry point (verified on-device; the legacy CameraActivity name is
# not exported as the launcher and `am start` against it silently fails).
ACTIVITY="$PACKAGE/com.android.camera.CameraLauncher"

# --- APK auto-tracking -----------------------------------------------------
# Rather than pinning one build, resolve the newest BSG MGC "aweme" APK from
# the celsoazevedo listing at runtime and install it if the device isn't
# already on it. Selection rule: highest base version, then highest V-number
# (e.g. MGC_9.7.047_V19_aweme.apk beats both _V18 and 9.6.080_V38).
#
#  - LISTING_URL is scraped for MGC_<base>_V<n>_aweme.apk filenames.
#  - MIRROR_BASE is the celsoazevedo direct-download host. The leading
#      "<n>-dontsharethislink" subdomain rotates but any mirror serves the
#      same files; "1-" is used here.
#  - BUILD_MARKER records the last-installed filename so repeat runs don't
#      re-download ~450 MB when already current (BSG mod revisions often share
#      the same Android versionName, so the marker -- not versionName -- is
#      what distinguishes V-builds).
#
# NOTE: there is no SHA256 verification here (auto-tracking trades the pinned
# integrity check for always-latest). A basic size sanity check guards against
# saving an HTML error page as an .apk.
LISTING_URL="https://www.celsoazevedo.com/files/android/google-camera/dev-bsg/"
MIRROR_BASE="https://1-dontsharethislink.celsoazevedo.com/file/filesc"
APK_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/gcam-installer"
BUILD_MARKER="$APK_CACHE_DIR/installed-build.txt"
MIN_APK_BYTES=$((50 * 1024 * 1024))   # sanity floor: a real MGC APK is ~450 MB
LATEST_APK_FILENAME=""                 # memoized by resolve_latest_apk

# Parse arguments
TARGET_USER=""
APK_PATH=""
SKIP_APK=false
FORCE_REINSTALL=false

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
        --apk)
            APK_PATH="$2"
            shift 2
            ;;
        --no-apk)
            SKIP_APK=true
            shift
            ;;
        --reinstall)
            FORCE_REINSTALL=true
            shift
            ;;
        -h|--help)
            sed -n '3,38p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--user <id>] [--all] [--apk PATH] [--no-apk] [--reinstall]"
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

# --- APK install / upgrade -------------------------------------------------
# Helpers below are responsible for getting the device onto the latest MGC
# aweme build before we touch shared_prefs. They no-op if the latest build is
# already installed (per the build marker) or if --no-apk is passed.

get_installed_version() {
    adb shell "dumpsys package $PACKAGE 2>/dev/null" 2>/dev/null \
        | grep -E '^\s*versionName=' \
        | head -1 \
        | sed -E 's/.*versionName=//' \
        | tr -d '\r'
}

resolve_latest_apk() {
    # Scrape the BSG listing for MGC_<base>_V<n> build names and pick the newest
    # (highest base version, then highest V); the aweme variant filename is
    # "<base>_aweme.apk". Memoized into the global LATEST_APK_FILENAME.
    [[ -n "$LATEST_APK_FILENAME" ]] && return 0

    if ! command -v curl &>/dev/null; then
        echo "ERROR: curl not found; install curl or pass --apk PATH." >&2
        return 1
    fi

    local html
    if ! html=$(curl --fail --silent --location --max-time 60 \
            -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
            -H "Referer: https://www.celsoazevedo.com/files/android/google-camera/" \
            "$LISTING_URL"); then
        echo "ERROR: could not fetch the BSG listing ($LISTING_URL)." >&2
        echo "  Check connectivity, or download manually and pass --apk PATH." >&2
        return 1
    fi

    # The listing shows base build names (e.g. "MGC_9.7.047_V19"); the aweme
    # variant is "<base>_aweme.apk". sort -V on field 2 (base version) then
    # field 3 (V<n>) puts the newest last.
    local base
    base=$(printf '%s\n' "$html" \
        | grep -oE 'MGC_[0-9]+\.[0-9]+\.[0-9]+_V[0-9]+' \
        | sort -u -t_ -k2,2V -k3,3V \
        | tail -1)

    if [[ -z "$base" ]]; then
        echo "ERROR: no MGC_<ver>_V<n> build found on the listing page." >&2
        echo "  The site layout may have changed; download manually from" >&2
        echo "  celsoazevedo.com and re-run with --apk PATH." >&2
        return 1
    fi
    LATEST_APK_FILENAME="${base}_aweme.apk"
    return 0
}

fetch_apk() {
    # Resolves $APK_PATH to a local APK: a user-provided --apk, a cached copy of
    # the latest build, or a fresh download of the latest build.
    if [[ -n "$APK_PATH" ]]; then
        if [[ ! -f "$APK_PATH" ]]; then
            echo "ERROR: --apk path does not exist: $APK_PATH" >&2
            return 1
        fi
        return 0
    fi

    resolve_latest_apk || return 1
    local target="$APK_CACHE_DIR/$LATEST_APK_FILENAME"
    mkdir -p "$APK_CACHE_DIR"

    if [[ -f "$target" ]]; then
        echo "  Using cached $LATEST_APK_FILENAME"
        APK_PATH="$target"
        return 0
    fi

    local url="$MIRROR_BASE/$LATEST_APK_FILENAME"
    echo "  Downloading $LATEST_APK_FILENAME from celsoazevedo.com..."
    echo "  -> $target"
    if ! curl --fail --location --progress-bar \
            --max-time 1800 \
            -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
            -H "Referer: https://www.celsoazevedo.com/files/android/google-camera/" \
            -o "$target.partial" \
            "$url"; then
        rm -f "$target.partial"
        echo "" >&2
        echo "ERROR: download failed ($url)." >&2
        echo "  The '<n>-dontsharethislink' subdomain rotates; download manually" >&2
        echo "  from celsoazevedo.com and re-run with --apk PATH." >&2
        return 1
    fi

    # Guard against a saved HTML error page (dropped SHA256 check means we lean
    # on a size floor to detect a bogus download).
    local bytes
    bytes=$(stat -c %s "$target.partial" 2>/dev/null || echo 0)
    if [[ "$bytes" -lt "$MIN_APK_BYTES" ]]; then
        rm -f "$target.partial"
        echo "ERROR: downloaded file is only $((bytes / 1024)) KB -- likely not a" >&2
        echo "  real APK (expired mirror link?). Try again or pass --apk PATH." >&2
        return 1
    fi

    mv "$target.partial" "$target"
    APK_PATH="$target"
    return 0
}

ensure_apk_installed() {
    if [[ "$SKIP_APK" == true ]]; then
        echo "Skipping APK install/upgrade check (--no-apk)."
        return 0
    fi

    local pkg_present=false installed=""
    if adb shell "pm list packages" 2>/dev/null | grep -q "^package:$PACKAGE\$"; then
        pkg_present=true
        installed=$(get_installed_version)
        echo "GCam package found: $PACKAGE  (version $installed)"
    else
        echo "GCam package $PACKAGE is NOT installed on the device."
    fi

    # In auto-track mode (no --apk), resolve the latest build and skip the
    # install when the marker says we're already on it.
    if [[ -z "$APK_PATH" ]]; then
        resolve_latest_apk || return 1
        echo "  Latest upstream build: $LATEST_APK_FILENAME"

        local marker=""
        [[ -f "$BUILD_MARKER" ]] && marker=$(tr -d '\r\n' < "$BUILD_MARKER" 2>/dev/null)

        if [[ "$pkg_present" == true && "$FORCE_REINSTALL" != true ]]; then
            if [[ "$marker" == "$LATEST_APK_FILENAME" ]]; then
                echo "  Already on latest build (per $BUILD_MARKER); skipping APK install."
                return 0
            fi
            if [[ -z "$marker" ]]; then
                echo "  Installed build unknown (no marker); (re)installing latest to be safe."
            else
                echo "  Installed build ($marker) != latest; will upgrade."
            fi
        fi
    fi

    fetch_apk || return 1

    echo "  Pushing APK to device and installing (this preserves app data)..."
    # -r: reinstall, keeping data
    # -d: allow downgrade (in case installed > candidate)
    # -g: grant runtime permissions on install (Android 6+)
    if ! adb install -r -d -g "$APK_PATH"; then
        echo "ERROR: adb install failed." >&2
        return 1
    fi

    local now
    now=$(get_installed_version)
    echo "  Installed versionName: $now"
    case "$now" in
        9.6.*|9.7.*) ;;
        *) echo "  WARNING: unexpected versionName '$now' (expected 9.6.x / 9.7.x)." >&2 ;;
    esac

    # Record which build we installed so future runs can skip redundant
    # downloads. basename() covers both auto-track and --apk paths.
    echo "$(basename "$APK_PATH")" > "$BUILD_MARKER" 2>/dev/null || true
}

ensure_apk_installed

# Installed version is informational from here on; the APK step above already
# put the device on the latest build (or was skipped via --no-apk). The config
# is schema-compatible with the 9.6.x / 9.7.x aweme BSG lineage.
VERSION_NAME=$(get_installed_version)
if [[ -z "$VERSION_NAME" ]]; then
    echo ""
    echo "ERROR: BSG GCam ($PACKAGE) is not installed and APK install was skipped."
    exit 1
fi
case "$VERSION_NAME" in
    9.6.*|9.7.*) ;;
    *)
        echo "  WARNING: config has only been validated against BSG 9.6.x and 9.7.x;"
        echo "           proceeding anyway."
        ;;
esac

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
        # 'test -s' = exists AND non-empty. 0-byte prefs files happen when
        # GCam is killed mid-write (e.g., right after our own force-stop)
        # and would otherwise crash the XML merger downstream. Treat as
        # fresh install in that case.
        if adb shell "su -c 'test -s $prefs_path'" </dev/null 2>/dev/null; then
            USER_HAS_PREFS[$user_id]=true
            echo "  User $user_id ($user_name): app data found, prefs exist"
        elif adb shell "su -c 'test -f $prefs_path'" </dev/null 2>/dev/null; then
            USER_HAS_PREFS[$user_id]=false
            echo "  User $user_id ($user_name): app data found, prefs file is empty (treating as fresh install)"
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

    check_setting 'name="pref_video_stabilization_key">1<'         "EIS video stabilization enabled"
    check_setting 'name="pref_video_stabilization_ois_key">1<'     "OIS video stabilization enabled"
    check_setting 'name="pref_video_amethyst_key">AMETHYST_OFF<'   "HDR10/10-bit video off (green-snapshot fix)"
    check_setting 'name="device_key">husky<'                       "Pixel 8 Pro spoof"
    check_setting 'name="device_hdrplus_key_1">blueline<'          "HDR+ model (blueline)"
    check_setting 'name="pref_camera_id_list_key"'                 "Camera ID mapping"
    check_setting 'name="pref_lens_title_key_0">Main<'             "Lens labels"
    check_setting 'name="pref_aux_key">1<'                         "AUX cameras"
    check_setting 'name="lib_skipmetadatacheck_key_p0_0">1<'       "Metadata check skip"
    check_setting 'name="pref_codec_format">avc<'                  "Video codec: AVC (H.264)"
    check_setting 'name="pref_video_fps_p2018_key">FPS_60<'        "Video FPS: 60 on main profile (no auto)"
    check_setting 'name="pref_video_fps_4k_key">FPS_30<'           "Video FPS: 30 on 4K profile"

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
    echo "Done. Check that all lenses work and EIS video stabilization is on."
else
    echo "Done. Launch GCam manually to apply the settings."
fi
