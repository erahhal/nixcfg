## Since the steam path is written to by the windows
## installation, ownership is sometimes incorrect. This
## script fixes permissions on startup.
{ pkgs, userParams, ... }:
let
  # Create a wrapper script that fixes Steam permissions
  steamFixScript = pkgs.writeShellScript "fix-steam-permissions" ''
    ${pkgs.coreutils}/bin/mkdir -p /home/${userParams.username}/.local/share/Steam/steamapps
    ${pkgs.coreutils}/bin/chown -R ${userParams.username}:users /home/${userParams.username}/.local/share/Steam/steamapps
  '';
in
{
  # Add sudo rule for passwordless execution of the fix script
  security.sudo.extraRules = [
    {
      users = [ userParams.username ];
      commands = [
        {
          command = "${steamFixScript}";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Create systemd user service to fix Steam permissions at boot
  home-manager.users.${userParams.username} = {
    systemd.user.services.steam-fix-permissions = {
      Unit = {
        Description = "Fix Steam directory permissions";
        After = [ "network.target" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.sudo}/bin/sudo ${steamFixScript}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
