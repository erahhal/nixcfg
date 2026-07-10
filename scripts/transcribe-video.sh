#!/usr/bin/env bash
# Transcribe videos to SRT subtitles using whisper.cpp.
#
# Usage: transcribe-video.sh [-l lang] [-V] <file-or-directory>...
#   -l lang   language code (default: auto-detect; use e.g. "ja", "en")
#   -V        additionally pre-filter audio with Silero VAD. Rarely needed:
#             long silences are already handled by the region splitting
#             below, and VAD tends to drop very quiet speech (e.g. softly
#             trailing meditation guidance). Useful only for recordings
#             whose pauses have too much background noise for silencedetect.
#
# Directories are searched recursively for video files. A video is skipped
# if a .srt with the same basename already exists (the .srt is only written
# after a fully successful transcription). Interrupted runs leave a
# <basename>.whisper.partial file and resume from the last decoded segment.
set -uo pipefail

# Use ffmpeg/whisper-cpp from PATH if installed; otherwise re-exec inside a
# nix shell. The registry pins nixpkgs to the system flake's locked revision,
# and the flake eval cache keeps repeat startups fast.
if ! command -v ffmpeg >/dev/null 2>&1 \
   || ! command -v whisper-cli >/dev/null 2>&1 \
   || ! command -v whisper-cpp-download-ggml-model >/dev/null 2>&1 \
   || ! command -v curl >/dev/null 2>&1; then
    exec nix shell nixpkgs#ffmpeg nixpkgs#whisper-cpp nixpkgs#curl --command "$0" "$@"
fi

LANG_OPT=auto
USE_VAD=0
while getopts "l:V" opt; do
    case $opt in
        l) LANG_OPT=$OPTARG ;;
        V) USE_VAD=1 ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -ge 1 ]] || { echo "usage: $0 [-l lang] [-V] <file-or-directory>..." >&2; exit 2; }

MODEL_DIR=${MODEL_DIR:-$HOME/.cache/whisper-models}
MODEL=$MODEL_DIR/ggml-large-v3-turbo.bin
VAD_MODEL=$MODEL_DIR/ggml-silero-v5.1.2.bin
mkdir -p "$MODEL_DIR"
if [[ ! -f $MODEL ]]; then
    echo "Downloading large-v3-turbo model (~1.6 GB, one time)..."
    whisper-cpp-download-ggml-model large-v3-turbo "$MODEL_DIR" || exit 1
fi
VAD_ARGS=()
if [[ $USE_VAD -eq 1 ]]; then
    if [[ ! -f $VAD_MODEL ]]; then
        curl -sfL -o "$VAD_MODEL" \
            https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin \
            || { rm -f "$VAD_MODEL"; echo "VAD model download failed" >&2; exit 1; }
    fi
    VAD_ARGS=(--vad --vad-model "$VAD_MODEL")
fi

AUDIO=$(mktemp --suffix=.wav)
trap 'rm -f "$AUDIO" "$AUDIO.region.wav"' EXIT

ms_to_s() { printf '%d.%03d' $(($1 / 1000)) $(($1 % 1000)); }

# Collect video files from the arguments
VIDEOS=()
for arg in "$@"; do
    if [[ -d $arg ]]; then
        while IFS= read -r -d '' f; do VIDEOS+=("$f"); done < <(
            find -L "$arg" -type f -regextype posix-extended \
                 -iregex '.*\.(mkv|mp4|mov|avi|webm|m4v|mpg|mpeg|ts|wmv)' -print0 | sort -z)
    elif [[ -f $arg ]]; then
        VIDEOS+=("$arg")
    else
        echo "warning: no such file or directory: $arg" >&2
    fi
done
[[ ${#VIDEOS[@]} -ge 1 ]] || { echo "no video files found" >&2; exit 1; }

# On resume the audio is extracted starting at the resume point (whisper's
# own --offset-t is unreliable together with VAD), so whisper emits
# slice-relative timestamps; this shifts them back to absolute video time
# as they stream past.
shift_timestamps() {
    awk -v off="$1" '
    function toms(t,  a) { split(t, a, /[:.]/); return ((a[1]*60+a[2])*60+a[3])*1000+a[4] }
    function tots(ms,  h, m, s) {
        h = int(ms/3600000); ms -= h*3600000
        m = int(ms/60000);   ms -= m*60000
        s = int(ms/1000);    ms -= s*1000
        return sprintf("%02d:%02d:%02d.%03d", h, m, s, ms)
    }
    /^\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\.[0-9][0-9][0-9] --> / {
        t1 = substr($0, 2, 12); t2 = substr($0, 19, 12); rest = substr($0, 31)
        printf "[%s --> %s%s\n", tots(toms(t1)+off), tots(toms(t2)+off), rest
        fflush(); next
    }
    { print; fflush() }'
}

# Convert accumulated "[HH:MM:SS.mmm --> HH:MM:SS.mmm]  text" lines to SRT
partial_to_srt() {
    awk '/^\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\.[0-9][0-9][0-9] --> / {
        t1 = substr($0, 2, 12); t2 = substr($0, 19, 12)
        txt = substr($0, 32); sub(/^ +/, "", txt)
        if (txt == "") next
        gsub(/\./, ",", t1); gsub(/\./, ",", t2)
        printf "%d\n%s --> %s\n%s\n\n", ++n, t1, t2, txt
    }' "$1"
}

transcribe_one() {
    local video=$1 base srt partial offset_ms=0 ts
    base=${video%.*}; srt=$base.srt; partial=$base.whisper.partial

    if [[ -f $srt ]]; then
        echo "=== skipping (already transcribed): $video"
        return 0
    fi

    if [[ -s $partial ]]; then
        ts=$(sed -n 's/^\[[0-9:.]* --> \([0-9:.]*\)\].*/\1/p' "$partial" | tail -1)
        if [[ -n $ts ]]; then
            local h m s ms
            IFS=':.' read -r h m s ms <<< "$ts"
            offset_ms=$((10#$h * 3600000 + 10#$m * 60000 + 10#$s * 1000 + 10#$ms))
            echo "=== resuming at $ts: $video"
        fi
    else
        echo "=== transcribing: $video"
    fi

    ffmpeg -y -v error -ss "$(ms_to_s "$offset_ms")" \
           -i "$video" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$AUDIO" \
        || { echo "audio extraction failed: $video" >&2; return 1; }

    # Split the audio into speech regions at silences longer than 2.5s and
    # transcribe each separately. Whisper happily emits one segment whose
    # text spans a long pause (start of cue tens of seconds before the words
    # are spoken); it can't do that if it never sees across a pause. Regions
    # are padded 250ms and everything is in ms relative to $AUDIO.
    local dur_ms regions
    dur_ms=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO" \
             | awk '{printf "%d", $1 * 1000}')
    regions=$(ffmpeg -i "$AUDIO" -af silencedetect=noise=-40dB:d=2.5 -f null - 2>&1 \
        | awk -v total="$dur_ms" '
            /silence_start:/ { for (i = 1; i <= NF; i++) if ($i == "silence_start:") ss = $(i+1)
                               e = (ss + 0.25) * 1000
                               if (e > prev + 400) printf "%d %d\n", prev, e }
            /silence_end:/   { for (i = 1; i <= NF; i++) if ($i == "silence_end:") prev = ($(i+1) - 0.25) * 1000
                               if (prev < 0) prev = 0 }
            END { if (total > prev + 400) printf "%d %d\n", prev, total }')
    [[ -n $regions ]] || regions="0 $dur_ms"

    # Segments stream to stdout as they are decoded; tee preserves progress
    # in the partial file so an interrupted run can resume where it stopped.
    # -mc 0 prevents repetition-loop hallucinations over music/silence.
    local rs re
    while read -r rs re; do
        ffmpeg -nostdin -y -v error -ss "$(ms_to_s "$rs")" -to "$(ms_to_s "$re")" \
               -i "$AUDIO" -c:a pcm_s16le "$AUDIO.region.wav" \
            || { echo "region extraction failed: $video" >&2; return 1; }
        whisper-cli -m "$MODEL" -f "$AUDIO.region.wav" -l "$LANG_OPT" -t "$(nproc)" -mc 0 \
                    "${VAD_ARGS[@]}" 2>/dev/null </dev/null \
            | shift_timestamps $((offset_ms + rs)) | tee -a "$partial" \
            || { echo "whisper failed: $video" >&2; return 1; }
    done <<< "$regions"

    partial_to_srt "$partial" > "$srt"
    rm -f "$partial"
    echo "=== done: $srt"
}

FAILED=0
for video in "${VIDEOS[@]}"; do
    transcribe_one "$video" || FAILED=1
done
exit $FAILED
