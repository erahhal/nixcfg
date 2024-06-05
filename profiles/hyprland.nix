{ inputs, hostParams, pkgs, userParams, ... }:
let
  # hyprland = pkgs.hyprland;
  hyprland = pkgs.hyprland-patched;
  # hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  hyprctl = "${hyprland}/bin/hyprctl";
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
    ../overlays/hyprland-patched-2.nix
  ];

  config = if (hostParams.defaultSession == "hyprland" || hostParams.multipleSessions) then {
    services.displayManager.sessionPackages = [hyprland ];

    programs.hyprland = {
      package = hyprland;
      enable = true;

      xwayland = {
        enable = true;
      };
    };

    environment.systemPackages = [
      hyprland
      hyprctl-curr
    ];

    # Load latest instead of stable
    # home-manager.sharedModules = [
    #   inputs.hyprland.homeManagerModules.default
    # ];

    home-manager.users.${userParams.username} = args@{ pkgs, ... }: {
      imports = [
        ( import ../home/profiles/hyprland.nix (args // {
          inputs = inputs;
          hostParams = hostParams;
        }))
      ];
    };
  } else {};
}
