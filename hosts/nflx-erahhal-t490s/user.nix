{ pkgs, copyDesktopIcons, copyDesktopItems, mkWindowsApp, hostParams, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  vespa-cli = pkgs.callPackage ../../pkgs/vespa-cli {};
in
{
  imports = [
    ../../profiles/syncthing.nix
  ];

  home-manager.users.${userParams.username} = {
    _module.args.hostParams = hostParams;
    _module.args.userParams = userParams;

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        bitwig-studio
        blender
        chromium
        jetbrains.datagrip
        jetbrains.idea-ultimate
        jetbrains-toolbox
        lutris
        mcreator
        # nodejs-16_x
        transmission-gtk

        # AI
        streamlit
        vespa-cli

        # Games
        prismlauncher
      ];
    };
  };
}
