#!/usr/bin/env bash
# Edit an image with a natural-language instruction using Qwen-Image-Edit-2511
# via stable-diffusion.cpp (Vulkan). Handles object add/remove, style transfer,
# text replacement, relighting, etc., while preserving the rest of the image.
#
# Usage: image-edit.sh [-o out.png] [-n steps] [--max-fidelity] <input-image> <instruction...>
#   e.g. image-edit.sh photo.jpg "remove the person in the background"
#   Defaults: out.png, 4 steps (the model is merged with the Lightning
#   4-step LoRA at runtime; without it the base model needs ~20 steps at
#   cfg 2.5, which takes ~10x longer — use --max-fidelity, an alias for
#   -n 20, to force that mode)
# Weights (~19 GB total) download to ~/.cache/stable-diffusion on first use.
set -uo pipefail

if ! command -v sd-cli >/dev/null 2>&1 && ! command -v sd >/dev/null 2>&1; then
    exec nix shell nixpkgs#stable-diffusion-cpp-vulkan nixpkgs#curl --command "$0" "$@"
fi
SD_BIN=$(command -v sd-cli || command -v sd)

# getopts has no long-option support; translate --max-fidelity first
# (options only — leave the instruction text alone)
ARGS=() IN_OPTS=1
for a in "$@"; do
    if [[ $IN_OPTS -eq 1 && $a == --max-fidelity ]]; then
        ARGS+=(-n 20)
    else
        [[ $a == -* ]] || IN_OPTS=0
        ARGS+=("$a")
    fi
done
set -- "${ARGS[@]}"

OUT=out.png STEPS=4
while getopts "o:n:" opt; do
    case $opt in
        o) OUT=$OPTARG ;;
        n) STEPS=$OPTARG ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -ge 2 && -f ${1:-} ]] || { echo "usage: $0 [-o out.png] [-n steps] <input-image> <instruction...>" >&2; exit 2; }
INPUT=$1
shift

MODEL_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/stable-diffusion
LORA_NAME=Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16
mkdir -p "$MODEL_DIR"
fetch() {
    [[ -f $MODEL_DIR/$1 ]] && return 0
    echo "Downloading $1 (one time)..." >&2
    curl -fL -o "$MODEL_DIR/$1" "$2" || { rm -f "$MODEL_DIR/$1"; exit 1; }
}
fetch qwen-image-edit-2511-Q4_K_M.gguf \
    https://huggingface.co/unsloth/Qwen-Image-Edit-2511-GGUF/resolve/main/qwen-image-edit-2511-Q4_K_M.gguf
fetch Qwen2.5-VL-7B-Instruct.Q4_K_M.gguf \
    https://huggingface.co/mradermacher/Qwen2.5-VL-7B-Instruct-GGUF/resolve/main/Qwen2.5-VL-7B-Instruct.Q4_K_M.gguf
fetch Qwen2.5-VL-7B-Instruct.mmproj-Q8_0.gguf \
    https://huggingface.co/mradermacher/Qwen2.5-VL-7B-Instruct-GGUF/resolve/main/Qwen2.5-VL-7B-Instruct.mmproj-Q8_0.gguf
fetch qwen_image_vae.safetensors \
    https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors
fetch "$LORA_NAME.safetensors" \
    "https://huggingface.co/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/main/$LORA_NAME.safetensors"

# Lightning (<=8 steps) runs at cfg 1.0 with the LoRA merged in; higher step
# counts mean the caller wants the base model behavior at cfg 2.5.
CFG=1.0 LORA_TAG="<lora:$LORA_NAME:1>"
if [[ $STEPS -gt 8 ]]; then
    CFG=2.5 LORA_TAG=""
fi

exec "$SD_BIN" --diffusion-model "$MODEL_DIR/qwen-image-edit-2511-Q4_K_M.gguf" \
               --llm "$MODEL_DIR/Qwen2.5-VL-7B-Instruct.Q4_K_M.gguf" \
               --llm_vision "$MODEL_DIR/Qwen2.5-VL-7B-Instruct.mmproj-Q8_0.gguf" \
               --vae "$MODEL_DIR/qwen_image_vae.safetensors" \
               --lora-model-dir "$MODEL_DIR" \
               --qwen-image-zero-cond-t --flow-shift 3 \
               --sampling-method euler --diffusion-fa --vae-tiling \
               --cfg-scale "$CFG" --steps "$STEPS" --seed -1 \
               -r "$INPUT" -p "$LORA_TAG $*" -o "$OUT"
