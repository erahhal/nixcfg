#!/usr/bin/env bash
# Chat with a local LLM via llama.cpp (Vulkan, runs on the iGPU).
#
# Usage: llm-chat.sh [-m model] [one-shot prompt...]
#   With no prompt, opens an interactive chat session.
#
# Models (downloaded to ~/.cache/llama.cpp on first use):
#   qwen     Qwen3.6-35B-A3B          ~20 GB  general use, strong ja<->en (default)
#   coder    Qwen3-Coder-30B-A3B      ~18 GB  coding
#   gpt-oss  gpt-oss-20b              ~12 GB  reasoning, math, tool use
#   gemma    Gemma 4 26B-A4B          ~15 GB  general use
set -uo pipefail

if ! command -v llama-cli >/dev/null 2>&1; then
    exec nix shell nixpkgs#llama-cpp-vulkan --command "$0" "$@"
fi

MODEL=qwen
while getopts "m:" opt; do
    case $opt in
        m) MODEL=$OPTARG ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))

case $MODEL in
    qwen)    HF=unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M ;;
    coder)   HF=unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M ;;
    gpt-oss) HF=ggml-org/gpt-oss-20b-GGUF ;;
    gemma)   HF=ggml-org/gemma-4-26B-A4B-it-GGUF ;;
    *) echo "unknown model: $MODEL (use qwen|coder|gpt-oss|gemma)" >&2; exit 2 ;;
esac

ARGS=(-hf "$HF" -ngl 999 -c 16384 --jinja)
if [[ $# -gt 0 ]]; then
    exec llama-cli "${ARGS[@]}" -no-cnv -p "$*"
fi
exec llama-cli "${ARGS[@]}"
