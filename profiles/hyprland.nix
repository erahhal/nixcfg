{ config, inputs, lib, pkgs, userParams, ... }:
let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  # In case of a long-lived session, e.g. in tmux after logging in and back out, this
  # is able to still connected to hyprland even though the socket changed.
  hyprctl-curr = pkgs.writeShellScriptBin "hyprctl-curr" ''
    CMDLINE=$(ps aux | grep "[s]ddm-helper")
    HYPRLAND_ID=$(echo $CMDLINE | sed 's/.*--id \([0-9]\+\) .*/\1/')

    ${hyprctl} -i $HYPRLAND_ID $@
  '';
  swayLockCommand = pkgs.callPackage ../pkgs/sway-lock-command { };
  hyprlockCommand = pkgs.callPackage ../pkgs/hyprlock-command { inputs = inputs; pkgs = pkgs; };
in
{
  config = lib.mkIf (config.hostParams.desktop.defaultSession == "hyprland" || config.hostParams.desktop.multipleSessions) {
    services.displayManager.sessionPackages = [pkgs.hyprland ];

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    ## As of v0.45, should no longer be crashing
    nixpkgs.overlays = if config.hostParams.desktop.useHyprlandFlake == true then [
      (final: prev: {
        hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      })
    ] else [];

    programs.hyprland = {
      enable = true;

      xwayland = {
        enable = true;
      };
    };

    environment.systemPackages = [
      pkgs.hyprland
      hyprctl-curr
    ];

    # Load latest instead of stable
    # home-manager.sharedModules = [
    #   inputs.hyprland.homeManagerModules.default
    # ];

    # Ignore lid switch, and let hyprland handle it using
    # the lid switch bindings below
    services.logind.settings.Login.HandleLidSwitch = "ignore";

    # services.acpid = {
    #   enable = true;
    #   logEvents = true;
    #   lidEventCommands =
    #   ''
    #     export PATH=$PATH:/run/current-system/sw/bin
    #
    #     lid_state=$(cat /proc/acpi/button/lid/LID/state | awk '{print $NF}')
    #     if [ $lid_state = "closed" ]; then
    #       # give time for WM to lock screen
    #       echo "Sleeping for 5 seconds..."
    #       sleep 5
    #       echo "Suspending"
    #       systemctl suspend
    #     fi
    #   '';
    #
    #   powerEventCommands =
    #   ''
    #     systemctl suspend
    #   '';
    # };


    home-manager.users.${userParams.username} = { pkgs, ... }: {
      imports = [
        ../home/profiles/hyprland.nix
      ];

      wayland.windowManager.hyprland = {
        settings = {
          bind = [
            (
              if config.hostParams.desktop.defaultLockProgram == "swaylock" then
                '',switch:on:Lid Switch,exec,${swayLockCommand} suspend''
              else
                '',switch:on:Lid Switch,exec,${hyprlockCommand} suspend''
            )
          ];
        };
      };
    };
  };
}
