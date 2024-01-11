{ pkgs, copyDesktopIcons, copyDesktopItems, mkWindowsApp, userParams, ... }:

let
  # fusion360 = pkgs.callPackage ../../pkgs/fusion360 {
  #   inherit copyDesktopItems;
  #   inherit copyDesktopIcons;
  #   inherit mkWindowsApp;
  # };
  fusion360 = pkgs.callPackage ../../pkgs/fusion360 { };
  bambu-studio = pkgs.callPackage ../../pkgs/bambu-studio { };
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  vespa-cli = pkgs.callPackage ../../pkgs/vespa-cli {};
in
{
  imports = [
    ../../profiles/syncthing.nix
  ];

  home-manager.users.${userParams.username} = {
    _module.args.userParams = userParams;

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        bambu-studio
        blender
        chromium
        unstable.jetbrains.idea-ultimate
        # fusion360
        lutris
        mcreator
        # nodejs-16_x
        trunk.prismlauncher
        trunk.jetbrains.datagrip
        transmission-gtk

        # AI
        streamlit
        vespa-cli

        ## python
        ## Currently broken
        # python39Packages.jupyter_core
        # python39Packages.nbconvert
        # python39Packages.mistune

        ## unstable
        trunk.bitwig-studio
      ];
    };
  };
}
