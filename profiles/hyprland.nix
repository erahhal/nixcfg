{ config, inputs, hostParams, pkgs, userParams, ... }:
let
  # In case of a long-lived session, e.g. in tmux after logging in and back out, this
  # is able to still connected to hyprland even though the socket changed.
  hyprctl-curr = pkgs.writeShellScriptBin "hyprctl-curr" ''
    CMDLINE=$(ps aux | grep "[s]ddm-helper")
    HYPRLAND_ID=$(echo $CMDLINE | sed 's/.*--id \([0-9]\+\) .*/\1/')

    hyprctl -i $HYPRLAND_ID $@
  '';
in
{
  config = if (hostParams.defaultSession == "hyprland" || hostParams.multipleSessions) then {
    # Make sure that /etc/pam.d/swaylock is added.
    # Otherwise swaylock doesn't unlock.
    security.pam.services.swaylock = {};

    services.xserver.displayManager.sessionPackages = [ pkgs.hyprland ];

    programs.hyprland = {
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      enable = true;

      xwayland = {
        enable = true;
      };

      # enableNvidiaPatches = true;
    };

    environment.systemPackages = [
      hyprctl-curr
    ];

    # XDG portals - allow desktop apps to use resources outside their sandbox
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk # gtk file dialogs
        ## seems to be already installed by hyperland?
        # xdg-desktop-portal-hyprland # Hyprland specific
      ];
      # gtkUsePortal = true;
    };

    # Load latest instead of stable
    home-manager.sharedModules = [
      inputs.hyprland.homeManagerModules.default
      inputs.hypridle.homeManagerModules.default
      inputs.hyprlock.homeManagerModules.default
      inputs.hyprpaper.homeManagerModules.default
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
