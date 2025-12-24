## Since the steam path is written to by the windows
## installation, ownership is sometimes incorrect. This
## script fixes permissions on startup.
{ pkgs, userParams, ... }:
{
  systemd.services.steam-fix-permissions = {
    description = "Fix Steam directory permissions";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-steam-permissions" ''
        STEAM_DIR="/home/${userParams.username}/.local/share/Steam"
        if [ -d "$STEAM_DIR" ]; then
          ${pkgs.coreutils}/bin/chown -R ${userParams.username}:users "$STEAM_DIR"
        fi
      '';
    };
  };
}
