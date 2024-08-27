{ config, inputs, hostParams, userParams, ... }:

{
  imports = [] ++ (if hostParams.defaultSession == "sway" || hostParams.multipleSessions then [
    # ../overlays/sway-xwayland-unscaled.nix
    # ../overlays/sway-with-dbus.nix
    # ../overlays/sway-with-nvidia-patches.nix
    # ../overlays/sway-with-input-methods.nix
  ] else []);

  config = if (hostParams.defaultSession == "sway" || hostParams.multipleSessions) then {
    # The NixOS option 'programs.sway.enable' is needed to make swaylock work,
    # since home-manager can't set PAM up to allow unlocks, along with some
    # other quirks.
    programs.sway = {
      enable = true;
      # nVidia support
      extraOptions = [
        "--unsupported-gpu"
      ];
      wrapperFeatures = {
        base = true; # run extraSessionCommands
        gtk = true;
      };
    };

    home-manager.users.${userParams.username} = args@{ pkgs, ... }: {
      imports = [
        ( import ../home/profiles/sway.nix (args // {
          launchAppsConfig = config.launchAppsConfigSway;
          inputs = inputs;
          hostParams = hostParams;
          userParams = userParams;
        }))
      ];
    };
  } else {};
}
