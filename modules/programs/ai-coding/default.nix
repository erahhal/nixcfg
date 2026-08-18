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
#   - claude-local         -> Claude Code via the genai-server control
#                             plane (~/.claude-local; pre-tuned env, plus
#                             the stack's tools over MCP — see below)
#
# Hermes AI agent from Nous Research. Configured against the genai-server
# control plane; provides isolated config dirs on other hosts:
#
#   - hermes               -> Hermes CLI with default OpenRouter provider
#   - hermes-local         -> Hermes with the genai-server control plane
#                             pre-configured
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
  ## every host and they all point at the same fleet. The damage
  ## was worst in claude-local, where an empty list means no context
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

  # THE CONTROL PLANE, not a node. Both endpoints below are
  # controller-scoped in genai-server's `serviceScope`, so this is the only
  # address either of them has ever had an answer at.
  #
  # It used to be `logistikon.lan`, from when that box was the whole
  # deployment, and the move to a control plane did not take these with it.
  # The models kept working, which is why nobody looked: genai-server ran a
  # LiteLLM on every machine (it was the one service missing from the role
  # table) so the node answered :4000 anyway. The MCP half did not and never
  # had — no node listens on the gateway's port — so all three harnesses
  # here spent weeks configured with a tool endpoint that refused every
  # connection, while the sessions themselves looked perfectly healthy.
  # genai-server scopes LiteLLM to the controller as of 2026-08-18, which
  # removes the copy that was covering for the stale address.
  #
  # WHAT THIS GIVES UP, said plainly because it was won by an outage. The
  # old arrangement pinned logistikon to loopback so that a hijacked
  # resolver or a VPN kill-switch could not strand the machine that hosted
  # the models (Mullvad's default "block local network sharing" did exactly
  # that on 2026-07-31). Loopback is not available any more — a node runs no
  # bridge to loop back to — so the route to the controller is now on the
  # path for every host including this one. An ADDRESS rather than a name
  # keeps the resolver off it, which is the half that can still be removed;
  # see hostParams.aiCoding.controllerHost.
  # Still asked, and still about the same thing: which hosts are certainly
  # adjacent to the fleet. It sets opencode's DEFAULT model, and a default
  # pointed at a server the machine may be nowhere near is a broken editor
  # rather than a broken option. logistikon is on the controller's LAN by
  # construction; a laptop is not.
  onLogistikon = config.networking.hostName == "logistikon";
  genaiHost = config.hostParams.aiCoding.controllerHost;
  genaiBaseUrl =
    "http://${genaiHost}:${toString config.hostParams.aiCoding.controllerLitellmPort}";
  genaiApiUrl = "${genaiBaseUrl}/v1";
  # The stack's MCP gateway (genai-server's `ports.mcpGateway`), a generic
  # OpenAPI->MCP bridge over its tool servers. Not remapped by the platform
  # hosting the controller, so unlike the bridge's port this is the stack's
  # own number.
  genaiMcpUrl = "http://${genaiHost}:8899/mcp";

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

  # Claude Code against the genai-server control plane (its LiteLLM
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
  # So the model is chosen per SESSION instead: `claude-local -m <id>`,
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
  claude-local = pkgs.writeShellScriptBin "claude-local" ''
    #!${pkgs.bash}/bin/bash
    export CLAUDE_CONFIG_DIR="$HOME/.claude-local"
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
          echo "current: $ANTHROPIC_MODEL   (claude-local -m <id>)"
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

  # StatusLine config shared by both claude and claude-local.
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
  # use `genaiApiUrl` (the controller's bridge) as the provider endpoint.
  hermes-local = pkgs.writeShellScriptBin "hermes-local" ''
    #!${pkgs.bash}/bin/bash
    export HERMES_HOME="$HOME/.hermes-local"
    mkdir -p "$HERMES_HOME"
    exec ${hermes}/bin/hermes "$@"
  '';

  # Declaratively manage hermes config for the local genai-server provider.
  # Similar to opencode's provider below, this sets up hermes to use
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
    # The stack's tools, from the same gateway claude-local and opencode
    # read. hermes speaks Streamable HTTP when a server entry carries a `url`
    # (stdio is `command`/`args`), and the gateway's `GET /mcp` -> 405 does
    # not trip hermes' content-type preflight — that probe rejects only a 2xx
    # carrying a definitely-non-MCP type, so `skip_preflight` is not needed
    # here.
    #
    # `timeout` is the PER-TOOL-CALL budget IN SECONDS and defaults to 300.
    # That is not enough: a generation tool can unload the chat model and
    # hold the card for longer, which is why the gateway's own ceiling is
    # 900s. Matched to it, so the two agree on when a call has failed rather
    # than hermes giving up on one still running.
    #
    # NOTE — no video exclusion here, unlike the other two harnesses. hermes
    # can disable a whole MCP server but has no per-tool filter in 0.19.0
    # (`mcp_servers.<name>.tools` is `{resources, prompts}`, not a name list).
    # It gets whatever the gateway publishes, which today is the chat-facing
    # spec with the ComfyUI graphs already left out; turning on
    # `mediaTools.chatWorkflows` would reach this harness with nothing here
    # to stop it.
    mcp_servers = {
      genai = {
        url = genaiMcpUrl;
        timeout = 900;
        connect_timeout = 60;
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

  # Everything claude-local gets that plain `claude` does not, beyond
  # the wrapper's env: the statusline (shared) plus the tool exclusions
  # below.
  #
  # WHY VIDEO IS DENIED HERE WHEN THE SERVER ALREADY DROPS IT. genai-server
  # decides this once, in `mediaTools.chatWorkflows` (off): the MCP gateway
  # reads media-tools' chat-facing spec, which leaves the eleven curated
  # ComfyUI graphs out, so today the gateway hands over 27 tools (~11k
  # tokens) and not one of them is a `workflow_`. This rule changes nothing
  # against that default and is not a second opinion about it — the server's
  # reasoning (a video graph is a minutes-long exclusive GPU hold assembled
  # from a form, which is Studio's job) is the same one that applies here,
  # only more so.
  #
  # It is here because that knob is global and its constituency is Open
  # WebUI: turning it on to give CHAT models video would also hand them to
  # a coding harness, ~12k tokens of schema for a capability no coding
  # session reaches for. This keeps the harness's set independent of that
  # decision. Drop the rule if the two should move together.
  #
  # A deny rule whose tool name is a bare glob REMOVES the tool from the
  # model's context rather than merely refusing the call, which is what
  # makes it worth writing at the client at all (verified on Claude Code
  # 2.1.223 against a stub endpoint, back when the gateway still served the
  # complete spec: 38 MCP tools handed to the model without the rule, 27
  # with it, and no `workflow_` among them). A glob matching nothing is not
  # a startup warning — names containing `_` or `*` are exempt from that
  # check — so it costs nothing while it is redundant.
  #
  # The glob is the whole video surface only because every graph
  # genai-server's `comfyui.workflows` ships today is a video graph — the
  # option is generic and its own example is a poster render. A non-video
  # graph added there would come through as `workflow_<name>` and be
  # excluded with them, so it would need naming here.
  claudeLocalManagedSettings = builtins.toJSON {
    inherit (builtins.fromJSON claudeStatusBarSettings) statusLine;
    permissions.deny = [ "mcp__genai__workflow_*" ];
  };

  # `*` rather than `+`: `+` replaces a whole top-level object, which would
  # drop any allow rules Claude Code has written next to our deny list.
  mergeClaudeLocalSettings = pkgs.writeShellScript "claude-local-settings-merge" ''
    set -eu
    settings="$HOME/.claude-local/settings.json"
    mkdir -p "$HOME/.claude-local"
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg claudeLocalManagedSettings} \
      '. * $managed' "$settings" > "$tmp"
    mv "$tmp" "$settings"
  '';

  # The genai stack's tools, over MCP. The gateway turns each tool server's
  # OpenAPI into MCP tools, so web search, image generation and editing,
  # segmentation, speech, the knowledge collections, the memory store and
  # the code sandbox all arrive without a second copy of any tool logic —
  # and a tool added to a tool server appears here on the gateway's next
  # refresh, with nothing to update on this side.
  #
  # WHY THIS IS MERGED IN RATHER THAN PASSED ON THE COMMAND LINE. Claude
  # Code reads MCP servers only from its config dir's `.claude.json`;
  # `settings.json` has no `mcpServers` key (checked on 2.1.223 — a server
  # declared there is silently ignored). The `--mcp-config` flag does work,
  # but it is VARIADIC: `claude --mcp-config f "$@"` eats the wrapper's
  # arguments, and appending it instead breaks every subcommand
  # (`claude-local mcp list`). So it goes in the file, the same way the
  # settings above do, and `*` keeps any server added with `claude mcp add`.
  claudeLocalMcp = builtins.toJSON {
    mcpServers.genai = { type = "http"; url = genaiMcpUrl; };
  };

  mergeClaudeLocalMcp = pkgs.writeShellScript "claude-local-mcp-merge" ''
    set -eu
    cfg="$HOME/.claude-local/.claude.json"
    mkdir -p "$HOME/.claude-local"
    [ -s "$cfg" ] || echo '{}' > "$cfg"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg claudeLocalMcp} \
      '. * $managed' "$cfg" > "$tmp"
    mv "$tmp" "$cfg"
  '';

  # opencode provider for the genai-server control plane, at
  # `genaiApiUrl`.
  #
  # THE PROVIDER IS STILL CALLED `logistikon` while the URL is the
  # controller's, and that is a deliberate hold rather than an oversight.
  # The id is half of a model name people type and opencode saves
  # (`logistikon/coder-pro`), so renaming it invalidates a selection rather
  # than a comment — and it is not simply wrong: the bridge moved, the
  # weights did not, and every bare name here still executes on that box.
  # Rename it when there is a second node to make it ambiguous.
  #
  # That is the LiteLLM bridge (`controllerLitellmPort`), whose
  # context_window_fallbacks silently continue an overflowing session on a
  # larger-window model — and which now forwards to each NODE's portal by
  # name, so `<model>@<node>` addresses one machine and the bare name falls
  # through the fleet. apiKey is required by the AI SDK client but ignored
  # server-side.
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
  # (non-thinking, agent-RL-trained, battle-tested tool parser, 256k);
  # `qwen38` is the A/B challenger, and as of 2026-08-17 it is also what
  # claude-local defaults to (hostParams.aiCoding.claudeModel) — so the
  # A/B is now running by itself, on the harness that has the eval suite
  # behind it, with opencode holding the control. It is the 96k half of the
  # 3.8 pair because that is what the `dense` alias resolves to; a session
  # that outgrows it reroutes to qwen38-long rather than dying. Claude Code
  # can drive thinking models — the bridge preserves reasoning_content as
  # of 2026-08-03, which is what made a thinking model eligible here at all.
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
    # The same tools claude-local gets, from the same gateway. opencode
    # registers an MCP server's tools as `<server>_<tool>`, so these arrive
    # as `genai_web_search`, `genai_generate_image` and so on.
    #
    # TIMEOUT IS NOT OPTIONAL HERE. opencode's default for an MCP request is
    # 5 SECONDS. Every generation tool on this box is slower than that
    # cold — the gateway's own ceiling is 900s because a tool call can
    # unload the chat model and hold the card for minutes — so at the
    # default `genai_generate_image` cannot succeed, and the failure looks
    # like a broken tool rather than a clock.
    mcp.genai = {
      type = "remote";
      url = genaiMcpUrl;
      enabled = true;
      timeout = 900000;
    };
    # Video, for the reason spelled out at claudeLocalManagedSettings:
    # already absent while `mediaTools.chatWorkflows` is off, kept out of the
    # harness if that is ever turned on for Open WebUI's sake. opencode's
    # `tools` map takes globs and is evaluated against the same
    # `<server>_<tool>` names.
    tools = { "genai_workflow_*" = false; };
  } // lib.optionalAttrs onLogistikon {
    model = "logistikon/coder-pro";
  };

  # Qwen Code (Alibaba's gemini-cli fork) against the local genai-server,
  # declared through its modelProviders catalog (the /model picker). Every
  # entry pins the LiteLLM bridge as baseUrl and reads the (server-ignored)
  # key from LOGISTIKON_API_KEY, which settings-level `env` exports at
  # startup — no secret, no wrapper script needed. The Qwen OAuth free tier
  # was discontinued 2026-04, so there's no login to protect and the plain
  # `qwen` command can default to the local fleet outright.
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

  # ~/.claude-logistikon -> ~/.claude-local, and the same for hermes.
  #
  # A RENAME OF A DIRECTORY THAT HOLDS DATA IS A MIGRATION, never a new
  # default. These hold session history, MCP approvals and whatever Claude
  # Code has written next to the keys this module manages; a wrapper that
  # simply started pointing somewhere else would come up looking healthy
  # with an empty history, which is the failure that reports nothing.
  #
  # ENTRY BY ENTRY rather than `mv` of the whole directory, because home-
  # manager may already have created the new one (it manages
  # `.hermes-local/config.yaml`), and a whole-directory move that declines
  # when the target exists would then silently never run. Anything already
  # present on the new side wins and the old copy is LEFT — this never
  # overwrites and never deletes, so a partial migration is inspectable
  # rather than lost.
  migrateHarnessDirs = pkgs.writeShellScript "ai-harness-dirs-migrate" ''
    set -eu
    migrate() {
      old="$HOME/$1"; new="$HOME/$2"
      [ -d "$old" ] || return 0
      mkdir -p "$new"
      moved=0 kept=0
      for f in "$old"/* "$old"/.[!.]*; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        if [ -e "$new/$base" ]; then kept=$((kept + 1)); continue; fi
        mv "$f" "$new/$base"; moved=$((moved + 1))
      done
      if rmdir "$old" 2>/dev/null; then
        # Not `[ ... ] && echo`: under `set -e` a bare && list whose test
        # fails IS the statement's exit status, so the nothing-to-do case
        # would abort activation.
        if [ "$moved" -gt 0 ]; then
          echo "moved $moved entries from $1 to $2"
        fi
      else
        echo "$1 still holds $kept entr(ies) that $2 already has; left alone"
      fi
      return 0
    }
    migrate .claude-logistikon .claude-local
    migrate .hermes-logistikon .hermes-local
  '';

  # The old names, kept working. They are what is in muscle memory and in
  # any script somebody wrote, and a command that vanishes on a rebuild is
  # a worse way to learn about a rename than one that says so and works.
  claude-logistikon-alias = pkgs.writeShellScriptBin "claude-logistikon" ''
    echo "claude-logistikon is now claude-local (it points at the control" >&2
    echo "plane rather than at one node); the old name still works." >&2
    exec ${claude-local}/bin/claude-local "$@"
  '';
  hermes-logistikon-alias = pkgs.writeShellScriptBin "hermes-logistikon" ''
    echo "hermes-logistikon is now hermes-local; the old name still works." >&2
    exec ${hermes-local}/bin/hermes-local "$@"
  '';

in
{
  # Function form so `lib` is home-manager's extended lib (lib.hm.*).
  home-manager.users.${username} = { lib, ... }: {
    home.packages = [
      claude-openrouter
      opencode-openrouter
      claude-local
      claude-logistikon-alias
      claude-statusbar
      hermes-local
      hermes-logistikon-alias
      pkgs.qwen-code
    ]
    # `hermes` (default, OpenRouter provider) collides with nflx-nixcfg's
    # Netflix-gateway `hermes` on Netflix hosts, so ship it only elsewhere —
    # same treatment as the default `opencode`. hermes-local (local
    # genai-server, isolated ~/.hermes-local, unique bin name) has no
    # collision and stays on every host, like claude-local.
    ++ lib.optionals (!userParams.nflxHost) [ pkgs.opencode hermes ];

    # First: the merges below mkdir the new directories, so a migration
    # ordered after them would find a target that already exists and move
    # nothing.
    home.activation.aiHarnessDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${migrateHarnessDirs}
    '';

    home.activation.claudeSettings = lib.hm.dag.entryAfter [ "aiHarnessDirs" ] ''
      run ${mergeClaudeSettings}
    '';

    home.activation.claudeLocalSettings = lib.hm.dag.entryAfter [ "aiHarnessDirs" ] ''
      run ${mergeClaudeLocalSettings}
    '';

    home.activation.claudeLocalMcp = lib.hm.dag.entryAfter [ "aiHarnessDirs" ] ''
      run ${mergeClaudeLocalMcp}
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

    # Separate config for hermes-local wrapper (isolated config dir).
    home.file.".hermes-local/config.yaml" = {
      text = lib.generators.toYAML { } hermesConfig;
    };

  };
}
