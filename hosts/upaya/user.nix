{ pkgs, hostParams, userParams, ... }:
let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  phockup = pkgs.callPackage ../../pkgs/phockup {};
  teensy-loader-gui = pkgs.callPackage ../../pkgs/teensy-loader-gui {};
in
{
  home-manager.users.${userParams.username} = {

    # ---------------------------------------------------------------------------
    # Host-specific user packages
    # ---------------------------------------------------------------------------

    imports = [
      ../../home/profiles/protonmail-bridge.nix
      ./hyprland.nix
    ];

    xresources = if hostParams.defaultSession == "none+i3" then {
      properties = {
        "Xft.dpi" = hostParams.dpiLaptop;
      };
    } else {};

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## Audio
        jack2Full
        qjackctl

        ## terminal apps
        exercism

        ## apps
        cool-retro-term
        blender-hip
        phockup
        simple-scan
        thunderbird
        transmission-gtk
        chromium

        ## games
        lutris
        steamtinkerlaunch
        mcreator
        prismlauncher
        atlauncher
        minecraft
        glfw3-minecraft
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
