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

  # Statusline for Claude Code showing 5h/7d rate-limit usage. Built from
  # the claude-statusbar flake input, so `nix flake update` pulls latest.
  claude-statusbar = pkgs.callPackage ../../../pkgs/claude-statusbar {
    src = inputs.claude-statusbar;
  };

  # Claude Code only reads statusLine from the mutable ~/.claude/settings.json
  # (no managed/system scope carries it), so declare it by merging the key in
  # at activation time and leaving the rest of the file to Claude Code.
  claudeStatusLine = builtins.toJSON {
    type = "command";
    command = "/etc/profiles/per-user/${username}/bin/cs render";
    refreshInterval = 1;
  };

  mergeClaudeStatusLine = pkgs.writeShellScript "claude-statusline-merge" ''
    set -eu
    settings="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --argjson sl ${lib.escapeShellArg claudeStatusLine} \
      '.statusLine = $sl' "$settings" > "$tmp"
    mv "$tmp" "$settings"
  '';
in
{
  # Function form so `lib` is home-manager's extended lib (lib.hm.*).
  home-manager.users.${username} = { lib, ... }: {
    home.packages = [
      claude-openrouter
      opencode-openrouter
      claude-statusbar
    ] ++ lib.optional (!userParams.nflxHost) pkgs.opencode;

    home.activation.claudeStatusLine = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeClaudeStatusLine}
    '';
  };
}
