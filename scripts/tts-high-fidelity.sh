#!/usr/bin/env bash
# High-quality text-to-speech (Kokoro-82M) — slower than tts.sh but far more
# natural. Alias for narrate.sh -t.
#
# Usage: tts-high-fidelity.sh [-v voice] [-s speed] <text...>
#        tts-high-fidelity.sh -L        list available voices
#   Text is read from stdin if not given.
if [[ $# -eq 0 && -t 0 ]]; then
    echo "usage: $0 [-v voice] [-s speed] <text...>   (or pipe text on stdin)" >&2
    echo "       $0 -L    list available voices" >&2
    exit 2
fi
exec "$(dirname "$(readlink -f "$0")")/narrate.sh" -t "$@"
