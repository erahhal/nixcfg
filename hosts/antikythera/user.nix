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
    ];

    programs.lan-mouse = {
      enable = true;
      systemd = true;
      settings = {
        port = 4242;
        authorized_fingerprints = {
          "c7:eb:bb:58:43:24:2f:6a:7f:10:8b:da:6c:64:a4:62:c8:91:bd:9e:70:09:ce:07:19:f9:a2:2b:e6:13:da:b1" = "nflx-erahhal-p16";
        };
        right = {
          hostname = "nflx-erahhal-p16.lan";
          activate_on_startup = true;
        };
      };
    };

    # Deskflow client configuration
    xdg.configFile."Deskflow/Deskflow.conf".text = ''
      [core]
      screenName=antikythera
      clientMode=true
      serverAddress=nflx-erahhal-p16.lan
      port=24800

      [gui]
      enableUpdateCheck=false
    '';

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
        blender

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
