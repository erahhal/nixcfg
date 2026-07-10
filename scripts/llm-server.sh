#!/usr/bin/env bash
# Serve a local LLM over an OpenAI-compatible API via llama.cpp (Vulkan).
# Endpoint: http://127.0.0.1:<port>/v1  (also a web UI at /)
#
# Usage: llm-server.sh [-m model] [-p port] [-e]
#   -m  qwen|coder|gpt-oss|gemma (default: qwen; see llm-chat.sh for sizes)
#   -p  port (default: 8080)
#   -e  serve the Qwen3-Embedding model instead (multilingual, /v1/embeddings)
set -uo pipefail

if ! command -v llama-server >/dev/null 2>&1; then
    exec nix shell nixpkgs#llama-cpp-vulkan --command "$0" "$@"
fi

MODEL=qwen PORT=8080 EMBED=0
while getopts "m:p:e" opt; do
    case $opt in
        m) MODEL=$OPTARG ;;
        p) PORT=$OPTARG ;;
        e) EMBED=1 ;;
        *) exit 2 ;;
    esac
done

if [[ $EMBED -eq 1 ]]; then
    # Qwen3-Embedding requires last-token pooling
    exec llama-server -hf Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0 --embedding \
                      --pooling last --host 127.0.0.1 --port "$PORT"
fi

case $MODEL in
    qwen)    HF=unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M ;;
    coder)   HF=unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M ;;
    gpt-oss) HF=ggml-org/gpt-oss-20b-GGUF ;;
    gemma)   HF=ggml-org/gemma-4-26B-A4B-it-GGUF ;;
    *) echo "unknown model: $MODEL (use qwen|coder|gpt-oss|gemma)" >&2; exit 2 ;;
esac

exec llama-server -hf "$HF" -ngl 999 -c 16384 --jinja \
                  --host 127.0.0.1 --port "$PORT"
