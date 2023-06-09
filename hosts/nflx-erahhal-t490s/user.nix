{ pkgs, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  vespa-cli = pkgs.callPackage ../../pkgs/vespa-cli {};
in
{
  imports = [
    ../../profiles/element.nix
    ../../profiles/signal.nix
    ../../profiles/syncthing.nix
  ];

  home-manager.users.${userParams.username} = {
    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        chromium
        unstable.jetbrains.idea-ultimate
        lutris
        mcreator
        # nodejs-16_x
        trunk.prismlauncher
        trunk.jetbrains.datagrip

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
