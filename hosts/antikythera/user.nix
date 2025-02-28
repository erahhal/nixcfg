{ pkgs, hostParams, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  teensy-loader-gui = pkgs.callPackage ../../pkgs/teensy-loader-gui {};
in
{
  imports = [
    ../../profiles/syncthing.nix
  ];

  home-manager.users.${userParams.username} = {
    _module.args.hostParams = hostParams;
    _module.args.userParams = userParams;

    imports = [
      # ../../home/profiles/protonmail-bridge.nix
      ./launch-apps-config-hyprland.nix
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## terminal apps
        exercism
        awscli
        postgresql
        firefox-wayland

        ## Dev and tools
        android-studio
        bitwig-studio
        blender-hip   # blender-hip is AMD hardware accelerated version of blender
        jetbrains.datagrip
        jetbrains.idea-ultimate

        ## Games
        atlauncher
        glfw-wayland-minecraft
        hmcl
        lutris
        mcreator
        minecraft
        prismlauncher
        steamtinkerlaunch
        wesnoth

        ## Desktop
        cool-retro-term
        thunderbird
        transmission_4-gtk
        nicotine-plus

        ## arduino
        arduino
        arduino-ide
        platformio
        teensy-loader-cli
        udev
        libudev0-shim
        gcc-arm-embedded
        teensy-loader-gui
        ## Conflicts with arduino IDE
        # teensyduino
      ];
    };
  };
}
