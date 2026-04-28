{ config, pkgs, lib, hostParams, ... }:
let userParams = config.hostParams.user; in
{
  home-manager.users.${userParams.username} = {

    imports = [
      ../../services/protonmail-bridge
      ../../programs/thunderbird
      ./hyprland.nix
      ./niri.nix
      ../../programs/clonehero
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        blender
        chromium
        nicotine-plus

        jetbrains-toolbox
        ## These are installed by jetbrains-toolbox with a corporate license
        # jetbrains.datagrip
        # jetbrains.idea-ultimate

        # lutris
        postgresql
        # nodejs-16_x
        qbittorrent
        transmission_4-gtk

        # AI
        # streamlit

        # Games
        prismlauncher

        ## unstable
        trunk.bitwig-studio

        ## arduino
        arduino
        arduino-ide
        # platformio
      ];
    };
  };
}

