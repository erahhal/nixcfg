{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.hostParams.desktop.displayManager == "dms" && config.hostParams.programs.steam.bootToSteam == false) {
    programs.dankMaterialShell.enable = true;

    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
    };

    services.greetd.enable = true;

    # Set the default session for the DMS greeter
    # DMS doesn't respect services.displayManager.defaultSession, so we write
    # the memory.json file directly to set the default session
    system.activationScripts.dmsGreeterDefaultSession = let
      defaultSessionPath = "/run/current-system/sw/share/wayland-sessions/${config.hostParams.desktop.defaultSession}.desktop";
    in ''
      mkdir -p /var/lib/dms-greeter
      CONFIG_FILE="/var/lib/dms-greeter/memory.json"
      DEFAULT_SESSION='${defaultSessionPath}'

      if [ -f "$CONFIG_FILE" ] && ${pkgs.jq}/bin/jq empty "$CONFIG_FILE" 2>/dev/null; then
        # Merge lastSessionId into existing valid JSON, preserving other fields like lastUser
        ${pkgs.jq}/bin/jq --arg session "$DEFAULT_SESSION" '.lastSessionId = $session' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      else
        # Create new file or replace invalid JSON
        echo '{"lastSessionId": "'"$DEFAULT_SESSION"'"}' | ${pkgs.jq}/bin/jq '.' > "$CONFIG_FILE"
      fi

      chown -R greeter:greeter /var/lib/dms-greeter
    '';
  };
}
