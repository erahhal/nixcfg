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
#   - opencode-local       -> opencode via the genai-server control plane
#                             (isolated XDG dirs, so it never touches the
#                             default or corp opencode config)
#   - claude-local         -> Claude Code via the genai-server control
#                             plane (~/.claude-local; pre-tuned env, plus
#                             the stack's tools over MCP — see below)
#   - claude-local-fanout  -> the same, on hostParams.aiCoding.fanoutModel:
#                             the wide-window model, for sessions that will
#                             run a background subagent beside the
#                             conversation (they share one KV pool)
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
# personal-login variants). NOTHING HERE CONFIGURES THAT COMMAND any more —
# it is whatever the host it is on says it is, and the local fleet is
# `opencode-local` on every host including the ones where the plain name is
# already spoken for.
{ config, pkgs, lib, inputs, ... }:

let
  userParams = config.hostParams.user;

  ## Claude Code's BACKGROUND slot (titles, small classification calls).
  ## Empty pins it to the session's main model, which is the historical
  ## behaviour. Named for Claude Code specifically because qwen-code has an
  ## unrelated `fastModel` setting of its own further down.
  claudeBackgroundModel = config.hostParams.aiCoding.claudeBackgroundModel;

  ## What every *-local harness defaults to. One option, read in three
  ## places, so they cannot drift apart the way they did.
  localModel = config.hostParams.aiCoding.localModel;

  ## The wide-window model `claude-local-fanout` runs on. See the option for
  ## the measurement; the short version is that llama-server's four slots
  ## share ONE KV pool the size of the window, so a background subagent and
  ## the conversation split it rather than getting one each.
  fanoutModel = config.hostParams.aiCoding.fanoutModel;

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

  # opencode against the genai-server control plane. Isolated XDG dirs for
  # the same reason as opencode-openrouter above, and one more that is the
  # whole point of this command existing:
  #
  # `opencode` MEANS DIFFERENT THINGS ON DIFFERENT MACHINES. On a work host
  # nflx-nixcfg owns that name and points it at the corp proxy; on a
  # personal one this module used to write the local fleet's provider into
  # the shared ~/.config/opencode/opencode.json. Same command, two servers,
  # decided by which laptop you happened to open — which is a coin-flip
  # about where a prompt goes, and no way to tell from the prompt.
  #
  # So the local one gets its own name and stops touching the default's
  # config at all. `opencode` is now whatever that host says it is,
  # `opencode-local` is this fleet everywhere, and `opencode-openrouter` is
  # OpenRouter — the same trio as claude/claude-local/claude-openrouter.
  # It carries no `pkgs.opencode` on the profile, so it is safe on a work
  # host where that name is already taken.
  opencode-local = pkgs.writeShellScriptBin "opencode-local" ''
    #!${pkgs.bash}/bin/bash
    export XDG_CONFIG_HOME="$HOME/.opencode-local/config"
    export XDG_DATA_HOME="$HOME/.opencode-local/data"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
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
    export ANTHROPIC_MODEL=''${ANTHROPIC_MODEL:-${localModel}}

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

  # `claude-local -m <fanoutModel>`, as a command.
  #
  # A WRAPPER RATHER THAN A SHELL ALIAS so it works from scripts, from
  # non-interactive shells and from anything that execs by name — the same
  # reason every other harness here is a writeShellScriptBin.
  #
  # It passes `-m` THROUGH claude-local instead of reimplementing anything.
  # That loop runs before the exports, so the model reaches the main,
  # sonnet, opus AND subagent slots together, and
  # CLAUDE_CODE_AUTO_COMPACT_WINDOW is recomputed from the chosen model's
  # real context rather than from the default's. Both halves matter here:
  # subagents are the reason this command exists, and a compaction threshold
  # left on the narrower model would compact early against the wide window.
  #
  # A `-m` on the command line still wins — the loop takes the last one — so
  # `claude-local-fanout -m coder-pro` is a one-off override, and
  # `claude-local-fanout -l` lists the fleet with this model as `current`.
  claude-local-fanout = pkgs.writeShellScriptBin "claude-local-fanout" ''
    exec ${claude-local}/bin/claude-local -m ${fanoutModel} "$@"
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
      default = localModel;
      provider = "local";
    };
    providers = {
      local = {
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
    # THIS IS THE HARNESS THAT GETS AN ALLOWLIST, and the note here used to
    # say it could not have one: "hermes has no per-tool filter in 0.19.0
    # (`mcp_servers.<name>.tools` is `{resources, prompts}`, not a name
    # list)". Those two booleans are real but they are siblings, not the
    # whole key. The same version reads `tools.include` (a whitelist) and
    # `tools.exclude`, include winning over exclude, and applies them per
    # tool before registration — `tools/mcp_tool.py`, `_should_register`.
    # Exact names only: it is a set membership test, so no globs.
    #
    # An allowlist is the shape the other two cannot express, and it is
    # better here for the reason written at genaiCodingTools: a tool added
    # to a tool server does not reach a coding session unless somebody adds
    # it. That also settles the video question this note was originally
    # about — turning on `mediaTools.chatWorkflows` no longer reaches this
    # harness, where before there was nothing here to stop it.
    mcp_servers = {
      genai = {
        url = genaiMcpUrl;
        timeout = 900;
        connect_timeout = 60;
        tools.include = genaiCodingTools.keep;
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

  # THE GENAI TOOLS A CODING SESSION WILL NEVER CALL, and what carrying
  # them costs. One list, rendered into both harnesses that can express it
  # (Claude Code's deny rules and opencode's `tools` map), because the
  # judgement is about the tools and not about the client.
  #
  # MEASURED 2026-08-18 against a stub endpoint — the method the workflow_
  # rule below already used, and no GPU: point a harness at a server that
  # records the request and answers once, then read the tool block it sent.
  # Claude Code 2.1.223 sends 58 tools, ~116k chars ~= 29k tokens, on EVERY
  # turn. That is 30% of qwen38's 96k window and 23% of qwen38-long's 128k
  # spent before a file is read. 34 of those tools (~12.3k tokens) are the
  # gateway's.
  #
  # Grouped by the gateway's own upstreams — `curl <controller>:8899/tools`
  # prints name -> upstream, which is how to re-derive this list rather than
  # trusting it:
  #
  #   media  19 tools ~10.8k tok   image generation and editing, faces, TTS, STT
  #   rag     7 tools  ~1.0k tok   four of them writes
  #   memory  6 tools  ~0.9k tok
  #   code    1 tool   ~0.4k tok   sandbox VM that cannot see this checkout
  #   search  1 tool   ~0.1k tok   web_search, the reason any of this is here
  #
  # KEPT: `web_search` and the three READ tools of the knowledge
  # collections. The call is per FAMILY rather than per tool, because a
  # family is what a tool server is:
  #   * media — a coding harness does not render pictures, and this is the
  #     whole 10.8k.
  #   * memory — Claude Code has its own memory and its own CLAUDE.md. A
  #     second store that only one of the two ever writes is worse than
  #     neither, because it looks like the box remembers.
  #   * rag writes and `drop_collection` — a coding session has no business
  #     mutating the box's collections, and dropping one is destructive
  #     enough that genai-server confirm-gates it.
  #   * `run_code` — Bash is right here. The sandbox is an ephemeral VM that
  #     cannot reach this machine, so the only code it can run is code this
  #     session has no interest in.
  #
  # BOTH HALVES ARE WRITTEN OUT because the harnesses need opposite ones:
  # hermes takes a whitelist, Claude Code and opencode can only be told what
  # to leave out. Together they are the gateway's inventory partitioned, and
  # `keep` is the half that survives a tool server gaining a tool — which is
  # the standing cost of the other two: something added to media-tools
  # arrives in a coding session ENABLED and unnamed, and the only thing that
  # notices is the window. The gateway's own comment celebrates precisely
  # that ("a tool added to a tool server appears here on the next refresh,
  # with nothing to update on this side"), and it is right, for chat.
  #
  # So: re-run the curl after adding a tool server, and expect `drop` to
  # need a line. `keep` will not.
  genaiCodingTools = {
    keep = [
      "web_search"
      # The READ side of the knowledge collections, ~440 tokens for all
      # three: looking something up in the box's own documents mid-task is
      # a plausible thing for a coding session to want.
      "list_collections" "list_documents" "search_documents"
    ];
    drop = [
      # media
      "create_mask" "edit_image" "face_frame_from_video" "generate_image"
      "generate_image_with_face" "group_faces_in_folder" "inpaint_image"
      "list_people" "list_regions" "photo_of_person" "portrait_from_video"
      "reimagine_image" "smart_edit" "swap_face" "swap_face_fast"
      "swap_face_full" "text_to_speech" "transcribe_audio" "who_is_this"
      # memory
      "consolidate_memories" "forget" "list_memories" "observe_conversation"
      "recall" "remember"
      # rag: the writes and the destructive one
      "drop_collection" "ingest_path" "ingest_text" "ingest_url"
      # sandbox
      "run_code"
    ];
  };

  # Everything claude-local gets that plain `claude` does not, beyond
  # the wrapper's env: the statusline (shared) plus the tool exclusions
  # below.
  #
  # WEBSEARCH IS DENIED BECAUSE IT CANNOT WORK HERE, and this is the one
  # rule that is about correctness rather than context. Claude Code sends it
  # as an ordinary client tool — verified in the same capture, no
  # server-side `type` on it — so the model can call it and does; what it
  # cannot do is answer, because the search behind it is Anthropic's and
  # this harness talks to the controller's bridge. The failure lands
  # mid-task as a tool error instead of arriving as "this harness has no
  # web", which is the worse of the two.
  #
  # `mcp__genai__web_search` is the replacement and was already on the
  # gateway: SearXNG on the controller, 473 chars of schema against
  # WebSearch's 877. Denying the built-in is also what stops a model
  # choosing the broken one when both are offered.
  #
  # WEBFETCH IS DELIBERATELY KEPT. It fetches the URL from THIS machine and
  # answers a prompt against it with the endpoint's own small-fast model,
  # which the wrapper pins to the local fleet — so it works, and nothing on
  # the gateway replaces it (`ingest_url` files a URL into a collection,
  # which is a different act, and is denied above).
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
  # CLAUDE CODE'S OWN TOOLS, CULLED THE SAME WAY AND FOR THE SAME REASON.
  # The gateway is not where the context goes: of the ~29k tokens of schema
  # on every turn, 16.7k is built-in and 12.3k is the stack's. `Workflow` by
  # itself is 5.5k — a fifth of the whole block, and more than the entire
  # media tool server.
  #
  # This half is claude-local only. opencode and hermes have their own
  # built-in sets and neither is expressed this way; the SHARED list is
  # genaiCodingTools, which is the gateway half.
  #
  # WHAT IS CULLED AND WHY — every one of these is a real capability, so the
  # test applied was "can it work on this box, driven by a 27B", not "is it
  # good":
  #   * Workflow (5.5k) — fans out dozens of subagents. There is one
  #     llama-swap slot behind this endpoint, so they do not run in
  #     parallel, they queue; and the GPU arbiter is what the queue collides
  #     with. The most expensive tool here is also the one this box is
  #     least able to run.
  #   * Cron x3, ScheduleWakeup (2.3k) — scheduling and /loop pacing. A
  #     local harness is started by a human at a terminal.
  #   * EnterWorktree/ExitWorktree (1.7k) — this fleet works in place.
  #   * ReportFindings (0.6k) — a rendering contract for /code-review only.
  #   * NotebookEdit (0.4k) — no Jupyter here.
  #   * TaskOutput (0.4k) — its own description begins "DEPRECATED", and the
  #     path it used to return now comes back from the tool that started the
  #     task. The rest of the Task family is NOT culled; see below.
  #
  # FOUR ARE DELIBERATELY KEPT, and two of them are kept BECAUSE `Agent` is.
  # Subagents stay by choice — a second pass costs time this box has and
  # buys an answer it might not otherwise get — and a kept capability should
  # not be left half-wired:
  #   * TaskCreate/Update/List/Get (2.2k) — the todo tracker, and the one
  #     line here that was culled and then put back deliberately. It is the
  #     harness remembering the plan instead of the model, which is worth
  #     more at 27B than at frontier scale: what it buys is a multi-step job
  #     that survives a compaction. 2.2k against a 96k window is the price
  #     of the model not losing the thread, and that is a good trade until
  #     something measures otherwise.
  #   * SendMessage (0.4k) is the only way to continue a spawned agent with
  #     its context intact. Culling it leaves `Agent` able to start work and
  #     unable to follow it up.
  #   * TaskStop (0.2k) is the off-switch. Agents run in the background by
  #     default, this is a shared GPU, and a runaway one holding the card is
  #     exactly the failure the arbiter exists to make rare — the model
  #     should be able to end its own.
  #   * Skill (0.5k) — slash commands are how the review and init flows are
  #     invoked at all.
  claudeBuiltinsOffForLocal = [
    "Workflow"
    "CronCreate" "CronDelete" "CronList" "ScheduleWakeup"
    "EnterWorktree" "ExitWorktree"
    "ReportFindings" "NotebookEdit"
    "TaskOutput"
  ];

  claudeLocalManagedSettings = builtins.toJSON {
    inherit (builtins.fromJSON claudeStatusBarSettings) statusLine;
    # Telemetry, crash reports and update checks off. THE KEYS ARE ENV
    # VARS, not settings fields — `telemetry`, `error_reporting` and
    # `allow_update_checks` are not in Claude Code's schema at all. Checked
    # against the deployed 2.1.223: "error_reporting" and
    # "allow_update_checks" appear ZERO times in the binary and
    # "telemetry" appears only as the name of a local log directory, so
    # writing those three here would produce a settings file that looks
    # configured and changes nothing. The four below are read.
    #
    # CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC, which the wrapper already
    # exports, is the umbrella over these. They are set explicitly anyway:
    # an umbrella is one release away from covering less than it did, and
    # nothing would announce that.
    env = {
      DISABLE_TELEMETRY = "1";
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_AUTOUPDATER = "1";
      DO_NOT_TRACK = "1";
    };
    # Measured end to end against the stub: 58 tools/~29.0k tokens ->
    # 17 tools/~6.1k, i.e. ~23k of window handed back on every turn.
    permissions.deny =
      [ "WebSearch" "mcp__genai__workflow_*" ]
      ++ claudeBuiltinsOffForLocal
      ++ map (t: "mcp__genai__${t}") genaiCodingTools.drop;
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

  # A managed CLAUDE.md for claude-local, and the one thing it has to say:
  # DELEGATE SYNCHRONOUSLY.
  #
  # `Agent` runs in the background by default — 2.1.223's own wording is
  # "Subagents run in the background by default ... Pass
  # `run_in_background: false` for a synchronous run" — which puts the
  # conversation and the agent on the card AT THE SAME TIME. Here that is
  # the expensive kind of concurrency: llama-server takes n_slots = 4
  # (`-np` is unset) and the slots share ONE KV pool the size of the
  # model's window, so two live streams split the window instead of each
  # getting one.
  #
  # Measured 2026-08-18 on qwen38-long: a 63,761-token conversation plus a
  # 32,730-token background subagent exhausted the 131,072 pool, and both
  # then retried for twenty minutes at 100% GPU without completing
  # anything — each attempt re-prefilling ~90k tokens for 73s before
  # llama.cpp returned 500 "Context size has been exceeded.". LiteLLM
  # cannot rescue that: it classifies a 500 as an InternalServerError, so
  # `context_window_fallbacks` (which does carry qwen38-long -> qwen) never
  # applies and the ladder is not consulted.
  #
  # NOT the same problem as ANTHROPIC_DEFAULT_HAIKU_MODEL, which was
  # measured INERT on this box on 2026-08-03 — see logistikon's config.
  # Background traffic does not go through that slot; subagents do go
  # through this one.
  #
  # It is written to a file of its own with CLAUDE.md importing it, rather
  # than into CLAUDE.md directly, for the same reason the settings above
  # are a jq merge and not a write: this half is managed and gets
  # overwritten, anything put beside it by hand survives.
  claudeLocalMemoryFile = "genai-fleet.md";
  claudeLocalMemory = ''
    # Running on the local fleet

    This session reaches ONE shared GPU through `claude-local`. Other
    people, and image and video work, share that card.

    ## Delegate synchronously

    Pass `run_in_background: false` when you use `Agent`.

    In the background — the default — your conversation and the agent are
    live on the card at once, and they do not get a context window each:
    every slot on the model server shares ONE pool the size of the model's
    window. Two live streams that no longer fit it BOTH fail, with
    `Context size has been exceeded.`, after re-prefilling their whole
    prompt first. So each failed attempt costs about a minute and retrying
    does not help.

    Delegating synchronously parks the parent. Its cached prefix becomes
    reclaimable, and one stream is live at a time.

    The budget, if you need to reason about it, is
    `sum(context + max_tokens) < window` across everything live at once.
    Launching several agents in one message is fine only when you know
    their contexts are small.
  '';

  writeClaudeLocalMemory = pkgs.writeShellScript "claude-local-memory" ''
    set -eu
    dir="$HOME/.claude-local"
    mkdir -p "$dir"
    install -m 644 ${pkgs.writeText claudeLocalMemoryFile claudeLocalMemory} \
      "$dir/${claudeLocalMemoryFile}"
    # The import line, added once. CLAUDE.md itself stays the user's file.
    if [ ! -e "$dir/CLAUDE.md" ] \
       || ! grep -qF "@${claudeLocalMemoryFile}" "$dir/CLAUDE.md"; then
      printf '@%s\n' "${claudeLocalMemoryFile}" >> "$dir/CLAUDE.md"
    fi
  '';

  # opencode provider for the genai-server control plane, at
  # `genaiApiUrl`.
  #
  # THE PROVIDER IS `local`, not the name of the machine the weights happen
  # to sit on. It was held at `logistikon` for one turn on the grounds that
  # the id is half of a model name people type and opencode SAVES, so
  # renaming it invalidates a selection rather than a comment. That reason
  # died with the move to a config dir of its own: `opencode-local` reads
  # ~/.opencode-local, which is new, so there is no saved selection to
  # invalidate and nothing has ever typed `logistikon/` into it.
  #
  # It is also the accurate name now. The bridge addresses each node by its
  # own suffix (`coder-pro@logistikon-eth`) and the bare names fall through
  # the fleet, so a provider standing for "the bare names" is standing for
  # the fleet rather than for one box.
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
  # options pin vendor sampling and neutralize that. The NUMBERS come from
  # each catalog entry (`temperature`/`topP`), never from here — a pair
  # written into this comment goes stale the moment the server retunes an
  # entry, and this one had said "temp 0.6, precise coding mode" for a while
  # after the catalog moved to 1.0/0.95. Read the entry, not this sentence.
  # Deliberately NOT set: small_model (titles already run on the
  # session's model; pinning one would *create* llama-swap churn),
  # interleaved (the SDK already round-trips reasoning_content, which
  # llama.cpp's preserve_thinking consumes), top_k/min_p (server-side
  # flags; LiteLLM may drop top_k).
  #
  # THE DEFAULT MODEL IS NOT DECIDED HERE any more. opencode held `coder-pro`
  # as the control arm of an A/B against `qwen38` on claude-local — but an
  # A/B whose result nobody reads is not an experiment, it is two harnesses
  # disagreeing about what this fleet codes on, and it survived a month past
  # the point where anyone was comparing. All three now read
  # hostParams.aiCoding.localModel, which carries the argument for whichever
  # model is current.
  #
  # Claude Code can drive thinking models — the bridge preserves
  # reasoning_content as of 2026-08-03, which is what made a thinking model
  # eligible for any of these at all.
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    # Binary is nix-managed; opencode must not self-update.
    autoupdate = false;
    # Drop old tool outputs before compacting — defers compaction, which
    # costs a full re-prefill on the local server.
    compaction.prune = true;
    # The title agent fires a concurrent request at session start, and a
    # concurrent request is the expensive kind here. llama-server takes
    # n_slots = 4 (`-np` is unset) and those slots SHARE one KV pool the
    # size of the window, so a second live stream does not get a window of
    # its own — it takes cells out of this one. Cheap case: it evicts the
    # session's prefix and titles become timestamps. Expensive case: the
    # two no longer fit and llama.cpp answers 500 "Context size has been
    # exceeded." after re-prefilling the whole prompt. Measured on
    # claude-local 2026-08-18; see claudeLocalMemory above.
    agent.title.disable = true;
    provider.local = {
      npm = "@ai-sdk/openai-compatible";
      name = "Local fleet";
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
    #
    # The rest of the exclusions are the SAME LIST claude-local denies, from
    # the same binding, so the two harnesses cannot end up carrying
    # different tool budgets against the same gateway. Written as exact
    # names rather than the glob families claude-local could have used: the
    # glob POSITIONS were verified on Claude Code (leading, middle and
    # trailing all match) and nothing here has verified opencode's, so this
    # side spends a longer list on not having to find out from a tool that
    # quietly stayed.
    #
    # No WebSearch equivalent to deny — opencode has no Anthropic web search
    # to break. Its own `webfetch` is the counterpart of the one Claude Code
    # keeps.
    tools = { "genai_workflow_*" = false; }
      // lib.listToAttrs
        (map (t: lib.nameValuePair "genai_${t}" false) genaiCodingTools.drop);
    # UNCONDITIONAL now, where it used to be logistikon-only. That gate was
    # right while this config was the SHARED one: a default model pointed at
    # a server the machine may be nowhere near would have hijacked
    # `opencode` on a laptop that had its own providers set up. In a config
    # dir of its own there are no other providers to hijack — leaving it
    # unset would just mean `opencode-local` starts with no model anywhere
    # but logistikon, which is a broken command rather than a polite one.
    #
    # The model itself comes from the same option claude-local and
    # hermes-local read, so the three cannot disagree about what this fleet
    # codes on.
    model = "local/${localModel}";
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
  # load plus a 256k prefill can take minutes.
  #
  # Followup suggestions are disabled — they fire extra concurrent requests
  # that compete for the server's shared KV pool (same reason opencode's title
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

in
{
  # A fanout model that is not WIDER than the default is the one way
  # `claude-local-fanout` can look configured and buy nothing: it would cost
  # a model switch and leave the shared KV pool exactly as tight as it was.
  # Same check, and the same reasoning, as genai-server's assertion on
  # `serve.overflowTo`.
  assertions = [
    {
      assertion = builtins.hasAttr fanoutModel genaiModels;
      message = "hostParams.aiCoding.fanoutModel = \"${fanoutModel}\" names no model this fleet serves. Known: "
        + lib.concatStringsSep ", " (lib.attrNames genaiModels);
    }
    {
      assertion = !(builtins.hasAttr fanoutModel genaiModels
                    && builtins.hasAttr localModel genaiModels)
        || genaiModels.${fanoutModel}.context > genaiModels.${localModel}.context;
      message = "hostParams.aiCoding.fanoutModel (\"${fanoutModel}\") must have a WIDER context than localModel"
        + " (\"${localModel}\"): claude-local-fanout exists to buy KV headroom for concurrent streams, and an"
        + " equal-or-narrower window buys none.";
    }
  ];

  # Function form so `lib` is home-manager's extended lib (lib.hm.*).
  home-manager.users.${username} = { lib, ... }: {
    home.packages = [
      claude-openrouter
      opencode-openrouter
      opencode-local
      claude-local
      claude-local-fanout
      claude-statusbar
      hermes-local
      pkgs.qwen-code
    ]
    # ONLY THE UNSUFFIXED NAMES ARE EVER GATED, and that is the rule rather
    # than a fact about these two. `opencode` and `hermes` collide with
    # nflx-nixcfg's own commands of those names on a work host, so they ship
    # elsewhere only. Everything above is `<tool>-local` or
    # `<tool>-openrouter`, which nflx-nixcfg does not use and never has —
    # checked, not assumed: it defines claude, hermes, codex, genai, pi,
    # agent-beach, newt and the `*-vanilla` variants, and mentions no
    # `-local` anywhere.
    #
    # So the local harnesses are on EVERY host, including the work one, and
    # a future gate here must not reach them. Each also execs its underlying
    # binary by store path rather than off PATH, so `hermes-local` runs OUR
    # hermes on a machine where `hermes` is the corp gateway. That is the
    # property that makes shipping them everywhere safe, and it is worth
    # keeping when any of these wrappers is touched.
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

    home.activation.claudeLocalMemory = lib.hm.dag.entryAfter [ "aiHarnessDirs" ] ''
      run ${writeClaudeLocalMemory}
    '';

    home.activation.qwenSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeQwenSettings}
    '';

    # The local fleet's provider, in `opencode-local`'s OWN config dir.
    #
    # It used to be written to xdg.configFile."opencode/opencode.json" — the
    # DEFAULT one — on non-Netflix hosts, which is what made `opencode` mean
    # the local fleet here and the corp proxy at work. Nothing writes the
    # default's config now, on any host: `opencode` is whatever that machine
    # says it is, and this fleet has a command of its own everywhere.
    #
    # Removing the old entry is enough to clean up after it. It was a
    # home-manager symlink, so the next activation takes exactly what it put
    # there and leaves the rest of ~/.config/opencode alone — including any
    # sessions and auth that were never ours.
    home.file.".opencode-local/config/opencode/opencode.json" = {
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
