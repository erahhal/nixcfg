{ inputs, hostParams, pkgs, userParams, ... }:
let
  # hyprland = pkgs.hyprland;
  # hyprland = pkgs.hyprland-patched;
  hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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
    # ../overlays/hyprland-patched.nix
  ];

  config = if (hostParams.defaultSession == "hyprland" || hostParams.multipleSessions) then {
    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    nixpkgs.config.packageOverrides = pkgs: {
      hyprland = pkgs.hyprland.override {
        debug = true;
      };
    };

    hardware.opengl = {
      package = pkgs-unstable.mesa.drivers;

      # if you also want 32-bit support (e.g for Steam)
      driSupport32Bit = true;
      package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
    };


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
