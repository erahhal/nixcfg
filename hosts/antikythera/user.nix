{ pkgs, hostParams, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  teensy-loader-gui = pkgs.callPackage ../../pkgs/teensy-loader-gui {};
  telegram-mz =  pkgs.writeShellScriptBin "telegram-mz" ''
    ${pkgs.telegram-desktop}/bin/Telegram -workdir ~/.mz
  '';
in
{
  imports = [
    # ../../profiles/syncthing.nix
  ];

  home-manager.users.${userParams.username} = {

    imports = [
      # ../../home/profiles/protonmail-bridge.nix
      ./hyprland.nix
      ./niri.nix
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        (pkgs.callPackage ../../pkgs/curseforge {})
        ## terminal apps
        exercism
        awscli
        postgresql

        ## Dev and tools
        android-studio
        bitwig-studio
        blender-hip   # blender-hip is AMD hardware accelerated version of blender

        ## Games
        atlauncher
        glfw3-minecraft
        hmcl
        lutris
        mcreator
        prismlauncher
        steamtinkerlaunch
        wesnoth

        ## Desktop
        cool-retro-term
        nicotine-plus
        telegram-desktop
        telegram-mz
        thunderbird
        transmission_4-gtk

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
