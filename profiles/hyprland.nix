args@{ config, inputs, hostParams, pkgs, userParams, ... }:
# let
#   flake-compat = builtins.fetchTarball {
#     url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
#     sha256 = "1prd9b1xx8c0sfwnyzkspplh30m613j42l1k789s521f4kv4c2z2";
#   };
#
#   hyprland = (import flake-compat {
#     src = builtins.fetchTarball {
#       url = "https://github.com/hyprwm/Hyprland/archive/master.tar.gz";
#       sha256 = "1vzk0kx7v4cvw75cabbbv96gl7lmjnm0mgwlw2l109awyg5ah39q";
#     };
#   }).defaultNix;
# in
{
  # imports = [hyprland.nixosModules.default];

  config = if hostParams.defaultSession == "hyprland" then {
    # nix.settings = {
    #   substituters = ["https://hyprland.cachix.org"];
    #   trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    # };

    services.xserver.displayManager.sessionPackages = [ pkgs.hyprland ];

    programs.hyprland = {
      enable = true;

      package = pkgs.hyprland.overrideAttrs (oldAttrs: {
        hidpiXWayland = true;
        nvidiaPatches = true;
      });

      xwayland = {
        enable = true;
        hidpi = true;
      };

      nvidiaPatches = true;
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
