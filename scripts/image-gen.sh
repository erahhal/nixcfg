#!/usr/bin/env bash
# Generate an image locally with Z-Image-Turbo (Alibaba, 6B) via
# stable-diffusion.cpp (Vulkan). Distilled for few-step generation; much
# better quality and text rendering than the SDXL era at similar speed.
#
# Usage: image-gen.sh [-o out.png] [-n steps] [-W width] [-H height] <prompt...>
#   Defaults: out.png, 8 steps, 1024x1024 (Z-Image's native resolution)
# Weights (~9 GB total: diffusion model + Qwen3-4B text encoder + VAE)
# download to ~/.cache/stable-diffusion on first use.
set -uo pipefail

if ! command -v sd-cli >/dev/null 2>&1 && ! command -v sd >/dev/null 2>&1; then
    exec nix shell nixpkgs#stable-diffusion-cpp-vulkan nixpkgs#curl --command "$0" "$@"
fi
SD_BIN=$(command -v sd-cli || command -v sd)

OUT=out.png STEPS=8 WIDTH=1024 HEIGHT=1024
while getopts "o:n:W:H:" opt; do
    case $opt in
        o) OUT=$OPTARG ;;
        n) STEPS=$OPTARG ;;
        W) WIDTH=$OPTARG ;;
        H) HEIGHT=$OPTARG ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -ge 1 ]] || { echo "usage: $0 [-o out.png] [-n steps] [-W width] [-H height] <prompt...>" >&2; exit 2; }

MODEL_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/stable-diffusion
mkdir -p "$MODEL_DIR"
fetch() {
    [[ -f $MODEL_DIR/$1 ]] && return 0
    echo "Downloading $1 (one time)..." >&2
    curl -fL -o "$MODEL_DIR/$1" "$2" || { rm -f "$MODEL_DIR/$1"; exit 1; }
}
fetch z_image_turbo-Q8_0.gguf \
    https://huggingface.co/leejet/Z-Image-Turbo-GGUF/resolve/main/z_image_turbo-Q8_0.gguf
fetch Qwen3-4B-Instruct-2507-Q4_K_M.gguf \
    https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/main/Qwen3-4B-Instruct-2507-Q4_K_M.gguf
fetch ae.safetensors \
    https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors

# Marker for "has completed successfully on this machine at least once".
# The first run also compiles the Vulkan shaders (a Mesa cache shared with
# all apps, not inspectable), which adds ~5 quiet minutes before sampling.
WARM_MARKER=$MODEL_DIR/.first-run-done
[[ -f $WARM_MARKER ]] || echo "note: first run compiles GPU shaders" \
    "- expect ~5 extra minutes before sampling starts; later runs take ~3 min total" >&2

"$SD_BIN" --diffusion-model "$MODEL_DIR/z_image_turbo-Q8_0.gguf" \
          --llm "$MODEL_DIR/Qwen3-4B-Instruct-2507-Q4_K_M.gguf" \
          --vae "$MODEL_DIR/ae.safetensors" \
          --diffusion-fa --vae-tiling --cfg-scale 1.0 --steps "$STEPS" \
          -W "$WIDTH" -H "$HEIGHT" --seed -1 \
          -p "$*" -o "$OUT" || exit
touch "$WARM_MARKER"
