#!/usr/bin/env bash
# Text-to-speech with Piper. Plays through the default audio output unless
# -o is given. Voices download to ~/.cache/piper-voices on first use.
#
# Usage: tts.sh [-v voice] [-o out.wav] [text...]
#   Text is read from stdin if not given as arguments.
#   Voice catalog + samples: https://rhasspy.github.io/piper-samples/
#   e.g. en_US-lessac-medium (default), en_US-libritts_r-medium, de_DE-thorsten-high
set -uo pipefail

if ! command -v piper >/dev/null 2>&1; then
    exec nix shell nixpkgs#piper-tts nixpkgs#curl --command "$0" "$@"
fi

VOICE=en_US-lessac-medium OUT=""
while getopts "v:o:" opt; do
    case $opt in
        v) VOICE=$OPTARG ;;
        o) OUT=$OPTARG ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))

# Voice names are <locale>-<name>-<quality>; the download path derives from them
LOCALE=${VOICE%%-*}; REST=${VOICE#*-}
NAME=${REST%-*}; QUALITY=${REST##*-}; LANG_CODE=${LOCALE%%_*}
VOICE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/piper-voices
VOICE_MODEL=$VOICE_DIR/$VOICE.onnx
if [[ ! -f $VOICE_MODEL ]]; then
    echo "Downloading voice $VOICE..." >&2
    mkdir -p "$VOICE_DIR"
    BASE=https://huggingface.co/rhasspy/piper-voices/resolve/main/$LANG_CODE/$LOCALE/$NAME/$QUALITY
    curl -fL -o "$VOICE_MODEL" "$BASE/$VOICE.onnx" \
        && curl -fL -o "$VOICE_MODEL.json" "$BASE/$VOICE.onnx.json" \
        || { rm -f "$VOICE_MODEL" "$VOICE_MODEL.json"; echo "voice download failed: $VOICE" >&2; exit 1; }
fi

if [[ $# -eq 0 && -t 0 ]]; then
    echo "usage: $0 [-v voice] [-o out.wav] <text...>   (or pipe text on stdin)" >&2
    echo "       voice catalog: https://rhasspy.github.io/piper-samples/" >&2
    exit 2
fi

PLAY=""
if [[ -z $OUT ]]; then
    OUT=$(mktemp --suffix=.wav)
    PLAY=1
    trap 'rm -f "$OUT"' EXIT
fi

if [[ $# -gt 0 ]]; then echo "$*"; else cat; fi \
    | piper -m "$VOICE_MODEL" -f "$OUT" >/dev/null

if [[ -n $PLAY ]]; then
    for player in pw-play paplay aplay; do
        command -v $player >/dev/null 2>&1 && exec $player "$OUT"
    done
    echo "no audio player found; output saved to $OUT" >&2
    trap - EXIT
fi
