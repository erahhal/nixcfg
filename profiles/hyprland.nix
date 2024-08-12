{ inputs, hostParams, pkgs, userParams, ... }:
let
  hyprland = pkgs.hyprland;
  # hyprland = pkgs.trunk.hyprland;
  # hyprland = pkgs.unstable.hyprland-patched;
  # hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  hyprctl = "${hyprland}/bin/hyprctl";
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

    # Ignore lid switch, and let hyprland handle it using
    # the lid switch bindings below
    services.logind.lidSwitch = "ignore";

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


    home-manager.users.${userParams.username} = args@{ pkgs, ... }: {
      imports = [
        ( import ../home/profiles/hyprland.nix (args // {
          inputs = inputs;
          hostParams = hostParams;
        }))
      ];

      wayland.windowManager.hyprland = {
        settings = {
          bind = [
            (
              if hostParams.defaultLockProgram == "swaylock" then
                '',switch:on:Lid Switch,exec,${swayLockCommand} suspend''
              else
                '',switch:on:Lid Switch,exec,${hyprlockCommand} suspend''
            )
          ];
        };
      };

    };
  } else {};
}
