#!/usr/bin/env bash
# Split audio into stems with Demucs (vocals / drums / bass / other).
# Output lands in ./separated/<model>/<track name>/.
#
# Usage: separate-stems.sh [-2] [-q] <audio-file>...
#   -2  two-stem mode: vocals + everything-else (karaoke/acapella)
#   -q  quick mode: single htdemucs model (default is the fine-tuned
#       htdemucs_ft ensemble — better quality, ~4x slower)
#
# Demucs is not in nixpkgs, so this runs it from PyPI via uvx (first run
# downloads pytorch, ~2.5 GB; needs nix-ld, which this system has).
# CPU-only, roughly a minute or two per track.
set -uo pipefail

if ! command -v uvx >/dev/null 2>&1; then
    exec nix shell nixpkgs#uv --command "$0" "$@"
fi

TWO_STEMS=() DEMUCS_MODEL=htdemucs_ft
while getopts "2q" opt; do
    case $opt in
        2) TWO_STEMS=(--two-stems=vocals) ;;
        q) DEMUCS_MODEL=htdemucs ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -ge 1 ]] || { echo "usage: $0 [-2] [-q] <audio-file>..." >&2; exit 2; }

exec uvx demucs -n "$DEMUCS_MODEL" "${TWO_STEMS[@]}" "$@"
