{ pkgs, lib, hostParams, userParams, ... }:
{
  home-manager.users.${userParams.username} = {

    imports = [
      ./launch-apps-config-hyprland.nix
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

        lutris
        postgresql
        # nodejs-16_x
        transmission_4-gtk

        # AI
        # streamlit
        # vespa-cli

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

