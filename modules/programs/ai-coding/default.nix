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
# Qwen Code (Alibaba's gemini-cli fork):
#
#   - qwen                 -> pre-configured against the local genai-server
#                             via a modelProviders catalog in ~/.qwen
#
# The default `claude` (subscription) comes from base-user's claude-code on
# every host. The default `opencode` package is installed here only on
# non-Netflix hosts; on Netflix nflx-nixcfg provides it (and its `*-vanilla`
# personal-login variants).
{ config, pkgs, lib, inputs, ... }:

let
  userParams = config.hostParams.user;

  ## Claude Code's BACKGROUND slot (titles, small classification calls).
  ## Empty pins it to the session's main model, which is the historical
  ## behaviour. Named for Claude Code specifically because qwen-code has an
  ## unrelated `fastModel` setting of its own further down.
  claudeBackgroundModel = config.hostParams.aiCoding.claudeBackgroundModel;

  ## The model list comes from the genai-server flake, not from a copy here.
  ##
  ## It used to be written out three times — opencode, qwen-code, hermes —
  ## and adding a model to the server did not add it to any of them. MiniMax
  ## sat unreachable in all three that way. genai-server publishes the list
  ## instead, with the sampling and window each model is served with, and
  ## updating the flake input is now the whole update.
  ##
  ## Read it from the FLAKE INPUT, which every host has. It used to read
  ## `config.services.genai-server.harnessModels`, and that is a NixOS
  ## option — it exists only on the one host that imports and enables the
  ## module. Everywhere else it silently evaluated to `{ }`, which is not
  ## "no models" in any useful sense: this module ships the harnesses on
  ## every host and they all point at logistikon over the LAN. The damage
  ## was worst in claude-logistikon, where an empty list means no context
  ## table, so CLAUDE_CODE_AUTO_COMPACT_WINDOW went unset and Claude Code
  ## fell back to assuming 200k against a 128k model.
  ##
  ## The option still wins where it exists: on the box that runs the fleet
  ## it is the exact served set, including models that host enables for
  ## itself (logistikon's `qwen-dense`) and excluding any its hardware
  ## floors skip. Off that box the flake's shipped catalog is the truth.
  hostGenaiModels = config.services.genai-server.harnessModels or { };
  genaiModels =
    if hostGenaiModels != { } then hostGenaiModels
    else inputs.genai-server.lib.harnessModels;
  ## 262144 -> "256k". Written the way people say a context window.
  ctxLabel = n: if n >= 1024 then "${toString (n / 1024)}k" else toString n;
  modelLabel = m: "${m.label} (${ctxLabel m.context})";
  orCfg = userParams.openrouter;
  username = userParams.username;

  # Endpoint for the local genai-server bridge (:4000). ON logistikon this
  # MUST be loopback, never the LAN name: nothing about `logistikon.lan`
  # survives a dead network, even though the server is on the same box. The
  # name resolves only via the router's DNS (it is not in /etc/hosts by
  # default, and no public resolver answers a `.lan` name), and it resolves to
  # the *wlan0* address — so one failure takes out both the lookup and the
  # route to an address that is 6 inches away. A VPN does exactly that:
  # switching Mullvad on with no configuration hijacks DNS and, with its
  # default "Local network sharing: block", drops traffic to 10.0.0.x —
  # stranding every harness on the machine that hosts the models, with no
  # working LLM left to debug the network with (2026-07-31 outage). Loopback
  # needs no resolver and no interface, and VPN kill-switches always permit
  # `lo`, so this path has nothing left to break.
  #
  # Other hosts keep the LAN name — it is the only way to reach the box from
  # them. On logistikon that name is *also* pinned to 127.0.0.1 in /etc/hosts,
  # which covers the browser/portal URLs this file does not own (see
  # modules/hosts/logistikon/configuration.nix).
  onLogistikon = config.networking.hostName == "logistikon";
  genaiHost = if onLogistikon then "127.0.0.1" else "logistikon.lan";
  genaiBaseUrl = "http://${genaiHost}:4000";
  genaiApiUrl = "${genaiBaseUrl}/v1";

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
  #  - thinking models are now SAFE here. The Anthropic bridge used to
  #    drop reasoning_content entirely (it routed /v1/messages through the
  #    OpenAI Responses API); as of 2026-08-03 it routes through
  #    chat-completions and LiteLLM is patched so the streaming adapter
  #    stops dropping each content block's first delta. Verified end to
  #    end against qwen-dense-long.
  # WHY THERE IS NO MODEL PICKER. Claude Code's /model list is not a query
  # against the endpoint — it is three alias slots (opus/sonnet/haiku) plus
  # whatever you type. Pointing those at DIFFERENT models breaks on this box:
  # the haiku/background/subagent traffic runs CONCURRENTLY with the main
  # model, so a single-slot llama-swap ends up trying to hold two models at
  # once. On a 32GB card with a 23GB dense model that is not a slowdown, it
  # is a failure to start. Hence all four pinned to one value.
  #
  # So the model is chosen per SESSION instead: `claude-logistikon -m <id>`,
  # or ANTHROPIC_MODEL in the environment. `-l` lists the fleet — generated
  # from genai-server's published catalog, so it cannot drift from the
  # server the way a hand-written list would.
  claudeModelIds = lib.attrNames genaiModels;
  claudeModelHelp = lib.concatMapStringsSep "\n" (n:
    let m = genaiModels.${n}; in
    "  ${n}${lib.fixedWidthString (lib.max 1 (18 - lib.stringLength n)) " " ""}${modelLabel m}")
    claudeModelIds;
  # id -> context, as a shell case. Claude Code has no idea how big a window
  # `qwen-dense-long` has: its table covers Anthropic model ids, and for
  # anything else it assumes the stock 200k. That is not cosmetic — it is why
  # a 128k model overflows instead of compacting, because auto-compaction
  # fires against the window Claude Code THINKS it has.
  claudeCtxCase = lib.concatMapStringsSep "\n" (n:
    "      ${n}) CTX=${toString genaiModels.${n}.context} ;;") claudeModelIds;
  claude-logistikon = pkgs.writeShellScriptBin "claude-logistikon" ''
    #!${pkgs.bash}/bin/bash
    export CLAUDE_CONFIG_DIR="$HOME/.claude-logistikon"
    export ANTHROPIC_BASE_URL="${genaiBaseUrl}"
    export ANTHROPIC_AUTH_TOKEN=dummy
    export ANTHROPIC_MODEL=''${ANTHROPIC_MODEL:-${config.hostParams.aiCoding.claudeModel}}

    # -m/--model picks the model for this session; -l/--list shows them.
    # Consumed here rather than passed through, so they never reach claude.
    while [ $# -gt 0 ]; do
      case "$1" in
        -m|--model) ANTHROPIC_MODEL="$2"; shift 2 ;;
        -l|--list)
          echo "models served by ${genaiBaseUrl}:"
          echo "${claudeModelHelp}"
          echo
          echo "current: $ANTHROPIC_MODEL   (claude-logistikon -m <id>)"
          echo "note: auto-compaction is set from each model's REAL window"
          echo "      (below), so a shorter one compacts sooner rather"
          echo "      than overflowing."
          exit 0 ;;
        *) break ;;
      esac
    done

    # Tell Claude Code the real window for the model it is about to use.
    # CLAUDE_CODE_AUTO_COMPACT_WINDOW is what auto-compaction measures
    # against, and the statusline percentage is re-derived from it too.
    # Unknown ids are left alone rather than guessed at.
    CTX=""
    case "$ANTHROPIC_MODEL" in
${claudeCtxCase}
    esac
    # Compact with room for the REPLY. The window holds prompt plus
    # generation, so compacting at the full context leaves nowhere to put
    # the answer — llama.cpp clamps rather than erroring, so the symptom
    # would be quietly truncated responses near the limit.
    export CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384
    [ -n "$CTX" ] && export CLAUDE_CODE_AUTO_COMPACT_WINDOW="$((CTX - CLAUDE_CODE_MAX_OUTPUT_TOKENS))"

    # Pinned together by default — see the comment above this wrapper. Two
    # GPU models resident at once is what this card cannot do, and
    # background traffic runs concurrently with the conversation.
    #
    # hostParams.aiCoding.claudeBackgroundModel moves ONLY the background
    # slot, and is only safe pointed at a model that costs no VRAM.
    # CLAUDE_CODE_SUBAGENT_MODEL stays on the main model regardless:
    # subagents do real work.
    BG="${claudeBackgroundModel}"
    [ -z "$BG" ] && BG="$ANTHROPIC_MODEL"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$BG"
    export ANTHROPIC_SMALL_FAST_MODEL="$BG"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_MODEL"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_MODEL"
    export CLAUDE_CODE_SUBAGENT_MODEL="$ANTHROPIC_MODEL"
    export CLAUDE_CODE_ATTRIBUTION_HEADER=0
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';

  # Statusline for Claude Code showing 5h/7d rate-limit usage. Built from
  # the claude-statusbar flake input, so `nix flake update` pulls latest.
  claude-statusbar = pkgs.callPackage ../../../pkgs/claude-statusbar {
    src = inputs.claude-statusbar;
  };

  # StatusLine config shared by both claude and claude-logistikon.
  claudeStatusBarSettings = builtins.toJSON {
    statusLine = {
      type = "command";
      command = "/etc/profiles/per-user/${username}/bin/cs render";
      refreshInterval = 1;
    };
  };

  # Hermes AI agent from Nous Research. Uses stdenv.mkDerivation to
  # pip-install hermes into a venv (bypasses pythonImportsCheck issues
  # since hermes manages its own dependencies via uv).
  hermes = pkgs.callPackage ../../../pkgs/hermes { };

  # Hermes CLI wrapper that configures it to use the local genai-server
  # by default. This provides a hermes command that's pre-configured to
  # use `genaiApiUrl` (the :4000 bridge) as the provider endpoint.
  hermes-logistikon = pkgs.writeShellScriptBin "hermes-logistikon" ''
    #!${pkgs.bash}/bin/bash
    export HERMES_HOME="$HOME/.hermes-logistikon"
    mkdir -p "$HERMES_HOME"
    exec ${hermes}/bin/hermes "$@"
  '';

  # Declaratively manage hermes config for the local genai-server provider.
  # Similar to opencode's provider.logistikon, this sets up hermes to use
  # the local genai-server (`genaiApiUrl`) as its default provider.
  # The hermes CLI reads its config from ~/.hermes/config.yaml, so we manage
  # that file declaratively.
  hermesConfig = {
    model = {
      default = "coder-pro";
      provider = "logistikon";
    };
    providers = {
      logistikon = {
        name = "litellm";
        base_url = genaiApiUrl;
        api_key = "dummy";
        discover_models = false;
        models = lib.mapAttrs (_: _: { }) genaiModels;
      };
    };
  };

  # Claude Code reads these only from the mutable ~/.claude/settings.json
  # (no managed/system scope carries them), so declare them by merging the
  # keys in at activation time and leaving the rest of the file to Claude
  # Code. includeCoAuthoredBy=false: no "Co-Authored-By: Claude" trailers in
  # commit messages. statusLine points at the claude-statusbar flake's `cs`
  # binary (see home.packages); on Netflix hosts nflx-nixcfg merges the same
  # `cs render` into ~/.claude and ~/.claude-vanilla.
  claudeManagedSettings = builtins.toJSON {
    includeCoAuthoredBy = false;
    statusLine = (builtins.fromJSON claudeStatusBarSettings).statusLine;
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

  mergeClaudeLogistikonSettings = pkgs.writeShellScript "claude-logistikon-settings-merge" ''
    set -eu
    settings="$HOME/.claude-logistikon/settings.json"
    mkdir -p "$HOME/.claude-logistikon"
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg claudeStatusBarSettings} \
      '. + $managed' "$settings" > "$tmp"
    mv "$tmp" "$settings"
  '';

  # opencode provider for the local genai-server (logistikon), at
  # `genaiApiUrl`. Port 4000 is the LiteLLM bridge, whose
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
  # that can't reach the box at all. coder-pro stays the default
  # (non-thinking, agent-RL-trained, battle-tested tool parser);
  # qwen-dense-long is the A/B challenger — same 77.2 vs 70.6 SWE-V
  # advantage, but thinking-mode, so it stays opt-in until proven in real
  # sessions. It is the LONG variant rather than qwen-dense because that
  # one (25744MiB) cannot coexist with the resident set and takes
  # transcription down with it; the long variant is the same weights at
  # 128k for MTP's ~1.7x speed, which speculative decoding makes a pure
  # throughput difference. Claude Code can drive thinking models now — the
  # bridge preserves reasoning_content as of 2026-08-03.
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
        baseURL = genaiApiUrl;
        apiKey = "dummy";
      };
      models = lib.mapAttrs (_: m: {
        name = modelLabel m;
        limit = { inherit (m) context output; };
        # Sampling mirrors each model's serve.preset on the box, so picking a
        # model here cannot silently sample it differently from every other
        # client talking to the same server.
        options = { temperature = m.temperature; top_p = m.topP; };
      }) genaiModels;
    };
  } // lib.optionalAttrs onLogistikon {
    model = "logistikon/coder-pro";
  };

  # Qwen Code (Alibaba's gemini-cli fork) against the local genai-server,
  # declared through its modelProviders catalog (the /model picker). Every
  # entry pins the LiteLLM bridge as baseUrl and reads the (server-ignored)
  # key from LOGISTIKON_API_KEY, which settings-level `env` exports at
  # startup — no secret, no wrapper script needed. The Qwen OAuth free tier
  # was discontinued 2026-04, so there's no login to protect and the plain
  # `qwen` command can default to logistikon outright.
  #
  # contextWindowSize / max_tokens mirror opencodeConfig above and MUST
  # likewise match each model's real `-c` in genai-server's module.nix;
  # samplingParams pin the same vendor sampling (a provider entry's
  # generationConfig is atomic — unset fields don't inherit, so sampling
  # and limits both live here). The OpenAI pipeline round-trips
  # reasoning_content, so the thinking models are safe from qwen-code
  # (unlike the Anthropic bridge). timeout is generous: a llama-swap model
  # load plus a single-slot 256k prefill can take minutes.
  #
  # Followup suggestions are disabled — they fire extra concurrent requests
  # that evict the single slot's prefix cache (same reason opencode's title
  # agent is off). fastModel stays unset so side calls run on the session's
  # model instead of forcing llama-swap churn (tool-use summaries then
  # no-op). gitCoAuthor off: no AI-attribution trailers, ever.
  qwenSettings = {
    general.enableAutoUpdate = false; # binary is nix-managed
    general.gitCoAuthor = { commit = false; pr = false; };
    privacy.usageStatisticsEnabled = false;
    ui.enableFollowupSuggestions = false;
    security.auth.selectedType = "openai";
    env.LOGISTIKON_API_KEY = "dummy";
    modelProviders.openai = map (m: {
      inherit (m) id name;
      envKey = "LOGISTIKON_API_KEY";
      baseUrl = genaiApiUrl;
      generationConfig = {
        timeout = 600000;
        contextWindowSize = m.context;
        samplingParams = { temperature = m.temperature; top_p = m.top_p; max_tokens = m.output; };
      };
    }) (lib.mapAttrsToList (_: m: {
      inherit (m) id context output temperature;
      name = modelLabel m;
      top_p = m.topP;
    }) genaiModels);
  };

  # ~/.qwen/settings.json must stay mutable (/model and /auth persist the
  # active selection back into it), so like the Claude settings above the
  # managed keys are jq-merged in at activation instead of symlinked from
  # the store. `*` deep-merges objects but replaces arrays, keeping our
  # modelProviders list authoritative while preserving anything else
  # qwen-code has written. model.name is only defaulted when absent so a
  # /model switch survives rebuilds.
  mergeQwenSettings = pkgs.writeShellScript "qwen-settings-merge" ''
    set -eu
    settings="$HOME/.qwen/settings.json"
    mkdir -p "$HOME/.qwen"
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg (builtins.toJSON qwenSettings)} \
      '. * $managed | .model.name //= "coder-pro"' "$settings" > "$tmp"
    mv "$tmp" "$settings"
  '';

in
{
  # Function form so `lib` is home-manager's extended lib (lib.hm.*).
  home-manager.users.${username} = { lib, ... }: {
    home.packages = [
      claude-openrouter
      opencode-openrouter
      claude-logistikon
      claude-statusbar
      hermes-logistikon
      pkgs.qwen-code
    ]
    # `hermes` (default, OpenRouter provider) collides with nflx-nixcfg's
    # Netflix-gateway `hermes` on Netflix hosts, so ship it only elsewhere —
    # same treatment as the default `opencode`. hermes-logistikon (local
    # genai-server, isolated ~/.hermes-logistikon, unique bin name) has no
    # collision and stays on every host, like claude-logistikon.
    ++ lib.optionals (!userParams.nflxHost) [ pkgs.opencode hermes ];

    home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeClaudeSettings}
    '';

    home.activation.claudeLogistikonSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeClaudeLogistikonSettings}
    '';

    home.activation.qwenSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeQwenSettings}
    '';

    # Declaratively manage the default opencode config with the local
    # genai-server provider. Non-Netflix hosts only (Netflix's opencode has
    # its own corp config); the default `opencode` above is likewise gated.
    xdg.configFile."opencode/opencode.json" = lib.mkIf (!userParams.nflxHost) {
      text = builtins.toJSON opencodeConfig;
    };

    # Default config for the plain `hermes` command (reads ~/.hermes/config.yaml).
    # Non-Netflix hosts only: on Netflix, nflx-nixcfg owns `hermes` and writes
    # ~/.hermes/config.yaml itself, so we must not also manage it here.
    home.file.".hermes/config.yaml" = lib.mkIf (!userParams.nflxHost) {
      text = lib.generators.toYAML { } hermesConfig;
    };

    # Separate config for hermes-logistikon wrapper (isolated config dir).
    home.file.".hermes-logistikon/config.yaml" = {
      text = lib.generators.toYAML { } hermesConfig;
    };

  };
}
