#!/usr/bin/env bash
# Ask a local vision model about an image (description, OCR — incl. Japanese,
# diagrams, etc.) using Qwen3-VL-8B via llama.cpp.
#
# Usage: describe-image.sh [-g] <image> [question...]
#   Default question: "Describe this image in detail."
#   -g  run on the iGPU (EXPERIMENTAL). The default is CPU-only because the
#       image-embedding prefill overruns the amdgpu job timeout on the 780M,
#       and the resulting GPU reset kills the desktop session
#       (https://github.com/ggml-org/llama.cpp/issues/21724). -g caps the
#       submission size (-ub 64), which may or may not be enough.
# Model (~6 GB) downloads to ~/.cache/llama.cpp on first use.
set -uo pipefail

if ! command -v llama-mtmd-cli >/dev/null 2>&1; then
    exec nix shell nixpkgs#llama-cpp-vulkan --command "$0" "$@"
fi

BACKEND_ARGS=(-ngl 0 --no-mmproj-offload)
while getopts "g" opt; do
    case $opt in
        g) BACKEND_ARGS=(-ngl 999 -b 512 -ub 64) ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -ge 1 && -f ${1:-} ]] || { echo "usage: $0 [-g] <image> [question...]" >&2; exit 2; }
IMAGE=$1
shift
PROMPT=${*:-Describe this image in detail.}

exec llama-mtmd-cli -hf unsloth/Qwen3-VL-8B-Instruct-GGUF:Q4_K_M "${BACKEND_ARGS[@]}" \
                    --image "$IMAGE" -p "$PROMPT"
