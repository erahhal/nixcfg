{ pkgs, lib, hostParams, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  blender = (pkgs.runCommandLocal "blender" { meta.broken = true; } (lib.warn "Package blender is currently disabled" "mkdir -p $out"));
in
{
  imports = [
    ../../profiles/syncthing.nix
  ];

  home-manager.users.${userParams.username} = {
    _module.args.hostParams = hostParams;
    _module.args.userParams = userParams;

    imports = [
      ./launch-apps-config-hyprland.nix
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        blender
        chromium

        jetbrains-toolbox
        ## These are installed by jetbrains-toolbox with a corporate license
        # jetbrains.datagrip
        # jetbrains.idea-ultimate

        lutris
        mcreator
        postgresql
        # nodejs-16_x
        transmission_3-gtk

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
        platformio
      ];
    };
  };
}
