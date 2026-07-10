#!/usr/bin/env bash
# Narrate an e-book or text file into a chaptered .m4b audiobook using
# Kokoro-82M via audiblez (runs from PyPI through uvx; needs nix-ld).
#
# Usage: narrate.sh [-v voice] [-s speed] <book.epub | file.txt | file.md>
#        narrate.sh [-v voice] [-s speed] -t <text...>
#   -v  Kokoro voice (default: af_heart). The prefix picks the language:
#       af_*/am_* American, bf_*/bm_* British, jf_*/jm_* Japanese,
#       ef_/em_ Spanish, ff_ French, if_/im_ Italian, pf_/pm_ Portuguese,
#       zf_/zm_ Chinese, hf_/hm_ Hindi. Samples: https://claudio.uk/posts/audiblez-v4.html
#   -s  speaking speed 0.5-2.0 (default 1.0)
#   -t  speak the remaining arguments (or stdin if none) aloud instead of
#       making an audiobook — high-quality counterpart to tts.sh
#   -L  list available voices and exit
#
# File mode output: <book>.m4b next to the input. Chapter WAVs accumulate in
# a <book>.narration.tmp/ work dir (kept on failure, removed on success).
# CPU synthesis runs at ~60-100 characters/sec: expect an hour or two for a
# novel. First run downloads pytorch + the model (several GB).
set -uo pipefail

if ! command -v uv >/dev/null 2>&1 || ! command -v espeak-ng >/dev/null 2>&1 \
   || ! command -v ffmpeg >/dev/null 2>&1 || ! command -v pandoc >/dev/null 2>&1; then
    exec nix shell nixpkgs#uv nixpkgs#espeak-ng nixpkgs#ffmpeg nixpkgs#pandoc \
         --command "$0" "$@"
fi

# audiblez/phonemizer look for libespeak-ng in /usr/lib, which doesn't exist
# on NixOS; both honor this env var. Without it, unusual tokens (like the
# audiobook intro's " – ") get mangled into audible junk ("nund").
if [[ -z ${ESPEAK_LIBRARY:-} ]]; then
    ESPEAK_LIBRARY=$(find "$(dirname "$(dirname "$(readlink -f "$(command -v espeak-ng)")")")/lib" \
                          -name 'libespeak-ng.so*' 2>/dev/null | head -1)
    [[ -n $ESPEAK_LIBRARY ]] && export ESPEAK_LIBRARY
fi

VOICE=af_heart SPEED=1.0 TEXT_MODE=0 LIST_VOICES=0
while getopts "v:s:tL" opt; do
    case $opt in
        v) VOICE=$OPTARG ;;
        s) SPEED=$OPTARG ;;
        t) TEXT_MODE=1 ;;
        L) LIST_VOICES=1 ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))

if [[ $LIST_VOICES -eq 1 ]]; then
    echo "Voice prefix = language + gender (af = American female, bm = British male, jf = Japanese female, ...)"
    echo "Samples: https://claudio.uk/posts/audiblez-v4.html"
    uvx audiblez --help 2>/dev/null | sed -n '/available voices:/,$p'
    exit 0
fi

# Text mode: drive Kokoro directly (audiblez is an audiobook tool that
# force-prepends a spoken "title – author." intro; for plain TTS we skip it
# and synthesize exactly the given text, nothing else)
if [[ $TEXT_MODE -eq 1 ]]; then
    if [[ $# -eq 0 && -t 0 ]]; then
        echo "usage: speak text aloud:  $0 [-v voice] [-s speed] -t <text...>   (or pipe text on stdin)" >&2
        echo "       list voices:      $0 -L" >&2
        exit 2
    fi
    TMPDIR_T=$(mktemp -d)
    trap 'rm -rf "$TMPDIR_T"' EXIT
    if [[ $# -gt 0 ]]; then echo "$*"; else cat; fi > "$TMPDIR_T/speech.txt"
    PYCODE='
import sys, warnings
warnings.filterwarnings("ignore")
print("Loading Kokoro model (~15-30s)...", file=sys.stderr)
import numpy as np, soundfile as sf
from kokoro import KPipeline
voice, speed, out = sys.argv[1], float(sys.argv[2]), sys.argv[3]
text = sys.stdin.read()
pipe = KPipeline(lang_code=voice[0])
print(f"Synthesizing ({voice})...", file=sys.stderr)
chunks = []
for i, (_, _, audio) in enumerate(pipe(text, voice=voice, speed=speed), 1):
    print(f"  segment {i} done", file=sys.stderr)
    chunks.append(audio.numpy())
sf.write(out, np.concatenate(chunks), 24000)
print("Playing...", file=sys.stderr)
'
    synth() {
        uv run "$@" --no-progress --with audiblez -- python -c "$PYCODE" \
               "$VOICE" "$SPEED" "$TMPDIR_T/speech.wav" < "$TMPDIR_T/speech.txt"
    }
    # --offline skips uv re-resolving dependencies over the network on every
    # run (slow spinner); fall back to online for the true first run
    echo "Preparing Python environment..." >&2
    synth --offline 2> >(grep -v HF_TOKEN >&2) \
        || { echo "(not cached yet - fetching dependencies, one time)" >&2
             synth || { echo "speech synthesis failed" >&2; exit 1; }; }
    for player in pw-play paplay aplay; do
        command -v $player >/dev/null 2>&1 && exec $player "$TMPDIR_T/speech.wav"
    done
    echo "no audio player found" >&2
    exit 1
fi

[[ $# -eq 1 && -f ${1:-} ]] || { echo "usage: $0 [-v voice] [-s speed] <book.epub|file.txt|file.md>  |  $0 [-v voice] [-s speed] -t <text...>" >&2; exit 2; }

INPUT=$(realpath "$1")
DIR=$(dirname "$INPUT")
BASE=$(basename "${INPUT%.*}")
WORKDIR=$DIR/$BASE.narration.tmp
mkdir -p "$WORKDIR"

EPUB=$INPUT
if [[ $INPUT != *.epub ]]; then
    EPUB=$WORKDIR/$BASE.epub
    # Title "." : audiblez always narrates "{title} – {author}." before
    # chapter 1, and an empty dc:title comes back from the XML parser as
    # Python None — audibly spoken as "None". A bare period is real text
    # (so no None) that Kokoro renders as silence. --epub-title-page=false
    # stops pandoc adding a second narratable title heading ("td" -> "tiad").
    pandoc "$INPUT" -o "$EPUB" --metadata title="." --epub-title-page=false \
        || { echo "pandoc conversion failed" >&2; exit 1; }
fi

# audiblez writes chapter WAVs and the final m4b into the current directory
(cd "$WORKDIR" && uvx audiblez "$EPUB" -v "$VOICE" -s "$SPEED") \
    || { echo "narration failed; partial chapters kept in $WORKDIR" >&2; exit 1; }

M4B=$(find "$WORKDIR" -maxdepth 1 -name '*.m4b' | head -1)
[[ -n $M4B ]] || { echo "no .m4b produced; see $WORKDIR" >&2; exit 1; }
# restore a real title in the m4b tags (the epub's was a placeholder ".")
ffmpeg -y -v error -i "$M4B" -c copy -metadata title="$BASE" "$DIR/$BASE.m4b" \
    || mv "$M4B" "$DIR/$BASE.m4b"
rm -rf "$WORKDIR"
echo "Done: $DIR/$BASE.m4b"
