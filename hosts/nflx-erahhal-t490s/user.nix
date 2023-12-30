{ pkgs, hostParams, userParams, ... }:

let
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
        blender
        chromium
        unstable.jetbrains.idea-ultimate
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
