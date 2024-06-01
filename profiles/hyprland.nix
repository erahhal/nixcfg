{ config, inputs, hostParams, pkgs, userParams, ... }:
let
  hyprctl = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl";
  # In case of a long-lived session, e.g. in tmux after logging in and back out, this
  # is able to still connected to hyprland even though the socket changed.
  hyprctl-curr = pkgs.writeShellScriptBin "hyprctl-curr" ''
    CMDLINE=$(ps aux | grep "[s]ddm-helper")
    HYPRLAND_ID=$(echo $CMDLINE | sed 's/.*--id \([0-9]\+\) .*/\1/')

    ${hyprctl} -i $HYPRLAND_ID $@
  '';
in
{
  imports = [
    # ../overlays/hyprland-patched.nix
  ];

  config = if (hostParams.defaultSession == "hyprland" || hostParams.multipleSessions) then {
    services.displayManager.sessionPackages = [ pkgs.hyprland ];

    programs.hyprland = {
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      # package = pkgs.hyprland-patched;
      enable = true;

      xwayland = {
        enable = true;
      };
    };

    environment.systemPackages = [
      # pkgs.hyprland-patched
      inputs.hyprland.packages.${pkgs.system}.hyprland
      hyprctl-curr
    ];

    # Load latest instead of stable
    home-manager.sharedModules = [
      inputs.hyprland.homeManagerModules.default
    ];

    home-manager.users.${userParams.username} = args@{ pkgs, ... }: {
      imports = [
        ( import ../home/profiles/hyprland.nix (args // {
          inputs = inputs;
          launchAppsConfig = config.launchAppsConfigHyprland;
          hostParams = hostParams;
        }))
      ];
    };
  } else {};
}
