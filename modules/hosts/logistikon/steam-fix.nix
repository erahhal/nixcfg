## Since the steam path is written to by the windows
## installation, ownership is sometimes incorrect. This
## script fixes permissions on startup.
{ config, pkgs, ... }:
let userParams = config.hostParams.user; in
{
  ## Override the flatpak Steam desktop file to add -cef-force-gpu flag.
  ## Without it, Steam hardcodes --disable-gpu on the CEF webhelper,
  ## causing extremely slow Big Picture mode (software rendering).
  home-manager.users.${userParams.username} = { lib, ... }: {
    home.activation.steam-flatpak-gpu-fix = lib.hm.dag.entryAfter [ "installPackages" ] ''
      FLATPAK_DESKTOP="/var/lib/flatpak/exports/share/applications/com.valvesoftware.Steam.desktop"
      LOCAL_DESKTOP="$HOME/.local/share/applications/com.valvesoftware.Steam.desktop"
      if [ -f "$FLATPAK_DESKTOP" ]; then
        mkdir -p "$HOME/.local/share/applications"
        sed '/^Exec=/s/com.valvesoftware.Steam /com.valvesoftware.Steam -cef-force-gpu -no-cef-sandbox /' \
          "$FLATPAK_DESKTOP" > "$LOCAL_DESKTOP"
      fi
    '';
  };

  systemd.services.steam-fix-permissions = {
    description = "Fix Steam directory permissions";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-steam-permissions" ''
        STEAM_DIR="/home/${userParams.username}/.local/share/Steam"

        # Fix ownership on shared Steam directory (Windows dual-boot changes ownership)
        if [ -d "$STEAM_DIR" ]; then
          ${pkgs.coreutils}/bin/chown -R ${userParams.username}:users "$STEAM_DIR"
        fi
      '';
    };
  };
}
