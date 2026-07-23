# Personal AI coding harnesses + OpenRouter commands.
#
# OpenRouter lives entirely here (never in nflx-nixcfg). On EVERY host we ship
# `claude-openrouter` and `opencode-openrouter`. They read the OpenRouter key
# from the shared agenix secret `openrouter-api-key` at runtime (never in the
# nix store) and keep their own isolated config dirs, so they never clobber the
# subscription / corp logins:
#
#   - claude-openrouter    -> Claude Code via OpenRouter (~/.claude-openrouter)
#   - opencode-openrouter  -> opencode via OpenRouter (isolated XDG dirs)
#   - claude-logistikon    -> Claude Code via the local genai-server bridge
#                             (~/.claude-logistikon; pre-tuned env, see below)
#
# Hermes AI agent from Nous Research. Configured to use the local genai-server
# on logistikon; provides isolated config dirs on other hosts:
#
#   - hermes               -> Hermes CLI with default OpenRouter provider
#   - hermes-logistikon    -> Hermes with local genai-server pre-configured
#
# The default `claude` (subscription) comes from base-user's claude-code on
# every host. The default `opencode` package is installed here only on
# non-Netflix hosts; on Netflix nflx-nixcfg provides it (and its `*-vanilla`
# personal-login variants).
{ config, pkgs, lib, inputs, ... }:

let
  userParams = config.hostParams.user;
  orCfg = userParams.openrouter;
  username = userParams.username;

  # Key file: explicit option wins; otherwise auto-detect the conventional
  # shared agenix secret `openrouter-api-key` if it's declared.
  apiKeyFile =
    if orCfg.apiKeyFile != null then orCfg.apiKeyFile
    else if config.age.secrets ? "openrouter-api-key"
    then config.age.secrets."openrouter-api-key".path
    else null;

  # Export <var> from the decrypted key file at runtime, if configured.
  openrouterExportKey = var:
    lib.optionalString (apiKeyFile != null) ''
      if [ -r "${apiKeyFile}" ]; then
        export ${var}="$(${pkgs.coreutils}/bin/cat "${apiKeyFile}")"
      fi
    '';

  # Claude Code against OpenRouter's Anthropic-compatible endpoint. Its own
  # config dir keeps the OpenRouter API-key session from clobbering the
  # subscription OAuth login that the default `claude` uses.
  claude-openrouter = pkgs.writeShellScriptBin "claude-openrouter" ''
    #!${pkgs.bash}/bin/bash
    export CLAUDE_CONFIG_DIR="$HOME/.claude-openrouter"
    export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
    ${openrouterExportKey "ANTHROPIC_API_KEY"}${lib.optionalString (orCfg.model != null) ''export ANTHROPIC_MODEL="${orCfg.model}"
    ''}
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';

  # opencode via OpenRouter. Isolated XDG dirs so it never touches the default
  # or corp opencode config; opencode's builtin openrouter provider reads
  # OPENROUTER_API_KEY from the env, so no in-app key entry is needed.
  opencode-openrouter = pkgs.writeShellScriptBin "opencode-openrouter" ''
    #!${pkgs.bash}/bin/bash
    export XDG_CONFIG_HOME="$HOME/.opencode-openrouter/config"
    export XDG_DATA_HOME="$HOME/.opencode-openrouter/data"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
    ${openrouterExportKey "OPENROUTER_API_KEY"}
    exec ${pkgs.opencode}/bin/opencode "$@"
  '';

  # Claude Code against the local genai-server (logistikon's LiteLLM
  # Anthropic bridge). Own config dir so the dummy-token session never
  # clobbers the subscription OAuth login. Env block mirrors the tuning in
  # genai-server's README:
  #  - haiku/background + subagent traffic pinned to the SAME warm model
  #    (anything else 404s on llama-swap or thrashes swaps)
  #  - attribution header off: it mutates the prompt prefix and silently
  #    defeats llama-server's prefix cache (full re-prefill every turn)
  #  - nonessential traffic off: parallel background calls serialize on the
  #    single slot and evict the prompt cache
  #  - NEVER point this at the thinking models (qwen/qwen-dense): the
  #    Anthropic bridge drops reasoning_content.
  claude-logistikon = pkgs.writeShellScriptBin "claude-logistikon" ''
    #!${pkgs.bash}/bin/bash
    export CLAUDE_CONFIG_DIR="$HOME/.claude-logistikon"
    export ANTHROPIC_BASE_URL="http://logistikon.lan:4000"
    export ANTHROPIC_AUTH_TOKEN=dummy
    export ANTHROPIC_MODEL=''${ANTHROPIC_MODEL:-coder-pro}
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_MODEL"
    export ANTHROPIC_SMALL_FAST_MODEL="$ANTHROPIC_MODEL"
    export CLAUDE_CODE_SUBAGENT_MODEL="$ANTHROPIC_MODEL"
    export CLAUDE_CODE_ATTRIBUTION_HEADER=0
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    export CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';

  # Statusline for Claude Code showing 5h/7d rate-limit usage. Built from
  # the claude-statusbar flake input, so `nix flake update` pulls latest.
  claude-statusbar = pkgs.callPackage ../../../pkgs/claude-statusbar {
    src = inputs.claude-statusbar;
  };

  # Hermes AI agent from Nous Research. Uses stdenv.mkDerivation to
  # pip-install hermes into a venv (bypasses pythonImportsCheck issues
  # since hermes manages its own dependencies via uv).
  hermes = pkgs.callPackage ../../../pkgs/hermes { };

  # Hermes CLI wrapper that configures it to use the local genai-server
  # by default. This provides a hermes command that's pre-configured to
  # use logistikon.lan:4000 as the provider endpoint.
  hermes-logistikon = pkgs.writeShellScriptBin "hermes-logistikon" ''
    #!${pkgs.bash}/bin/bash
    export HERMES_CONFIG_DIR="$HOME/.hermes-logistikon"
    export HERMES_DATA_DIR="$HOME/.hermes-logistikon/data"
    mkdir -p "$HERMES_CONFIG_DIR" "$HERMES_DATA_DIR"
    exec ${hermes}/bin/hermes "$@"
  '';

  # Declaratively manage hermes config for the local genai-server provider.
  # Similar to opencode's provider.logistikon, this sets up hermes to use
  # the local genai-server (logistikon.lan:4000) as its default provider.
  # The hermes CLI reads its config from ~/.hermes/config.yaml, so we manage
  # that file declaratively.
  hermesConfig = {
    provider = {
      name = "litellm";
      base_url = "http://logistikon.lan:4000/v1";
      api_key = "dummy";
    };
    model = "logistikon/coder-pro";
    models = [
      {
        name = "coder-pro";
        model = "Qwen3-Coder-Next-80B (256k, agentic)";
        context_window = 262144;
      }
      {
        name = "qwen-dense";
        model = "Qwen3.6-27B MTP (80k, top coder, thinking)";
        context_window = 81920;
      }
      {
        name = "glm-flash";
        model = "GLM-4.7-Flash (128k, fast agentic)";
        context_window = 131072;
      }
      {
        name = "qwen";
        model = "Qwen3.6-35B-A3B (256k, fast)";
        context_window = 262144;
      }
      {
        name = "research";
        model = "gpt-oss-120b (64k)";
        context_window = 65536;
      }
    ];
  };

  # Claude Code reads these only from the mutable ~/.claude/settings.json
  # (no managed/system scope carries them), so declare them by merging the
  # keys in at activation time and leaving the rest of the file to Claude
  # Code. includeCoAuthoredBy=false: no "Co-Authored-By: Claude" trailers in
  # commit messages. statusLine points at the claude-statusbar flake's `cs`
  # binary (see home.packages); on Netflix hosts nflx-nixcfg merges the same
  # `cs render` into ~/.claude and ~/.claude-vanilla.
  claudeManagedSettings = builtins.toJSON {
    statusLine = {
      type = "command";
      command = "/etc/profiles/per-user/${username}/bin/cs render";
      refreshInterval = 1;
    };
    includeCoAuthoredBy = false;
  };

  mergeClaudeSettings = pkgs.writeShellScript "claude-settings-merge" ''
    set -eu
    settings="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg claudeManagedSettings} \
      '. + $managed' "$settings" > "$tmp"
    mv "$tmp" "$settings"
  '';

  # opencode provider for the local genai-server (logistikon). Reachable on
  # the home LAN as logistikon.lan; port 4000 is the LiteLLM bridge, whose
  # context_window_fallbacks silently continue an overflowing session on a
  # larger-window model (it forwards to the 8897 dashboard filter proxy, so
  # not-ready models still 503 cleanly). apiKey is required by the AI SDK
  # client but ignored server-side.
  #
  # limit.context MUST match each model's real `-c` in genai-server's
  # module.nix — opencode otherwise assumes a huge window, blows past the
  # server's cap mid-session, and the session dies instead of compacting.
  # limit.output bounds a single response, not the window.
  #
  # Per-model `options` are spread raw into the request body (source-
  # verified in opencode 1.17/1.18 + @ai-sdk/openai-compatible), and they
  # matter: opencode sends NO temperature for custom models, but it DOES
  # force top_p=1.0 for any model id containing "qwen" — the explicit
  # options pin vendor sampling and neutralize that. temp 0.6/top_p 0.95 =
  # official Qwen3.6 "precise coding" mode (server default stays 1.0 for
  # chat). Deliberately NOT set: small_model (titles already run on the
  # session's model; pinning one would *create* llama-swap churn),
  # interleaved (the SDK already round-trips reasoning_content, which
  # llama.cpp's preserve_thinking consumes), top_k/min_p (server-side
  # flags; LiteLLM may drop top_k).
  #
  # The local server is made the default model only ON logistikon, so
  # opencode's default isn't hijacked on other (possibly off-LAN) hosts
  # where logistikon.lan wouldn't resolve. coder-pro stays the default
  # (non-thinking, agent-RL-trained, battle-tested tool parser);
  # qwen-dense is the A/B challenger — better benchmarks (77.2 vs 70.6
  # SWE-V) but thinking-mode, so it stays opt-in until proven in real
  # sessions. NEVER point Claude Code (Anthropic bridge) at the thinking
  # models — the bridge drops reasoning_content.
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    # Binary is nix-managed; opencode must not self-update.
    autoupdate = false;
    # Drop old tool outputs before compacting — defers compaction, which
    # costs a full re-prefill on the single-slot local server.
    compaction.prune = true;
    # The title agent fires a concurrent request at session start that
    # evicts the single slot's prefix cache (titles become timestamps).
    agent.title.disable = true;
    provider.logistikon = {
      npm = "@ai-sdk/openai-compatible";
      name = "Logistikon";
      options = {
        baseURL = "http://logistikon.lan:4000/v1";
        apiKey = "dummy";
      };
      models = {
        coder-pro = { name = "Qwen3-Coder-Next-80B (256k, agentic)"; limit = { context = 262144; output = 32768; }; options = { temperature = 1.0; top_p = 0.95; }; };
        qwen-dense = { name = "Qwen3.6-27B MTP (80k, top coder, thinking)"; limit = { context = 81920; output = 32768; }; options = { temperature = 0.6; top_p = 0.95; }; };
        glm-flash = { name = "GLM-4.7-Flash (128k, fast agentic)"; limit = { context = 131072; output = 32768; }; options = { temperature = 0.7; top_p = 1.0; }; };
        qwen = { name = "Qwen3.6-35B-A3B (256k, fast)"; limit = { context = 262144; output = 32768; }; options = { temperature = 0.6; top_p = 0.95; }; };
        qwen-uc = { name = "Qwen3.6-35B UC huihui (256k)"; limit = { context = 262144; output = 32768; }; options = { temperature = 0.6; top_p = 0.95; }; };
        qwen-dense-uc = { name = "Qwen3.6-27B UC huihui (128k)"; limit = { context = 131072; output = 32768; }; options = { temperature = 0.6; top_p = 0.95; }; };
        research = { name = "gpt-oss-120b (64k)"; limit = { context = 65536; output = 16384; }; options = { temperature = 1.0; top_p = 1.0; }; };
      };
    };
  } // lib.optionalAttrs (config.networking.hostName == "logistikon") {
    model = "logistikon/coder-pro";
  };

in
{
  # Function form so `lib` is home-manager's extended lib (lib.hm.*).
  home-manager.users.${username} = { lib, ... }: {
    home.packages = [
      claude-openrouter
      opencode-openrouter
      claude-logistikon
      claude-statusbar
      hermes
      hermes-logistikon
    ] ++ lib.optional (!userParams.nflxHost) pkgs.opencode;

    home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeClaudeSettings}
    '';

    # Declaratively manage the default opencode config with the local
    # genai-server provider. Non-Netflix hosts only (Netflix's opencode has
    # its own corp config); the default `opencode` above is likewise gated.
    xdg.configFile."opencode/opencode.json" = lib.mkIf (!userParams.nflxHost) {
      text = builtins.toJSON opencodeConfig;
    };

    # Declaratively manage hermes config for the local genai-server provider.
    xdg.configFile."hermes/config.yaml" = {
      text = lib.generators.toYAML { } hermesConfig;
    };

  };
}
