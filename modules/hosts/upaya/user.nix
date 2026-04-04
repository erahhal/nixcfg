{ pkgs, userParams, ... }:
let
  mcreator = pkgs.callPackage ../../../pkgs/mcreator {};
  phockup = pkgs.callPackage ../../../pkgs/phockup {};
  teensy-loader-gui = pkgs.callPackage ../../../pkgs/teensy-loader-gui {};
in
{
  home-manager.users.${userParams.username} = { osConfig, ... }: {

    # ---------------------------------------------------------------------------
    # Host-specific user packages
    # ---------------------------------------------------------------------------

    imports = [
      ../../services/protonmail-bridge
      ./hyprland.nix
    ];

    xresources = if osConfig.hostParams.desktop.defaultSession == "none+i3" then {
      properties = {
        "Xft.dpi" = osConfig.hostParams.desktop.dpi;
      };
    } else {};

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## Audio

        ## terminal apps
        exercism

        ## apps
        cool-retro-term
        blender
        phockup
        simple-scan
        thunderbird
        transmission_4-gtk
        chromium

        ## games
        lutris
        steamtinkerlaunch
        mcreator
        prismlauncher
        atlauncher
        # minecraft — removed from nixpkgs, use prismlauncher
        # glfw3-minecraft
        hmcl
        wesnoth

        ## dev
        android-studio

        ## arduino
        platformio
        teensy-loader-cli
        udev
        libudev0-shim
        gcc-arm-embedded
        teensy-loader-gui
        teensyduino

        ## unstable
        unstable.bitwig-studio
      ];
    };
  };
}
