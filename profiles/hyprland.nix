args@{ config, inputs, hostParams, pkgs, userParams, ... }:
{
  config = if hostParams.defaultSession == "hyprland" then {

    # Make sure that /etc/pam.d/swaylock is added.
    # Otherwise swaylock doesn't unlock.
    security.pam.services.swaylock = {};

    services.xserver.displayManager.sessionPackages = [ pkgs.hyprland ];

    programs.hyprland = {
      enable = true;

      xwayland = {
        enable = true;
      };

      enableNvidiaPatches = true;
    };

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

    home-manager.sharedModules = [
      inputs.hyprland.homeManagerModules.default
    ];

    home-manager.users.${userParams.username} = { pkgs, ... }: {
      imports = [
        ( import ../home/profiles/hyprland.nix (args // { launchAppsConfig = config.launchAppsConfig; }))
      ];
    };
  } else {};
}
