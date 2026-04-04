## Since the steam path is written to by the windows
## installation, ownership is sometimes incorrect. This
## script fixes permissions on startup.
##
## Also sets up a symlink so flatpak Steam uses the shared
## ~/.local/share/Steam directory directly (for dual-boot
## Windows game sharing).
{ pkgs, userParams, ... }:
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
    description = "Fix Steam directory permissions and flatpak symlink";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-steam-permissions" ''
        STEAM_DIR="/home/${userParams.username}/.local/share/Steam"
        FLATPAK_STEAMAPPS="/home/${userParams.username}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps"
        HOST_STEAMAPPS="$STEAM_DIR/steamapps"

        # Fix ownership on shared Steam directory (Windows dual-boot changes ownership)
        if [ -d "$STEAM_DIR" ]; then
          ${pkgs.coreutils}/bin/chown -R ${userParams.username}:users "$STEAM_DIR"
        fi

        # Symlink flatpak Steam's steamapps to the shared directory so flatpak
        # sees all installed games without manual library folder setup
        if [ -L "$FLATPAK_STEAMAPPS" ]; then
          echo "Flatpak steamapps symlink already exists"
        elif [ -d "$HOST_STEAMAPPS" ]; then
          if [ -d "$FLATPAK_STEAMAPPS" ]; then
            ${pkgs.coreutils}/bin/rm -rf "$FLATPAK_STEAMAPPS"
          fi
          ${pkgs.coreutils}/bin/ln -s "$HOST_STEAMAPPS" "$FLATPAK_STEAMAPPS"
          ${pkgs.coreutils}/bin/chown -h ${userParams.username}:users "$FLATPAK_STEAMAPPS"
          echo "Created flatpak steamapps symlink: $FLATPAK_STEAMAPPS -> $HOST_STEAMAPPS"
        fi
      '';
    };
  };
}
