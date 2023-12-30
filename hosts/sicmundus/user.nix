{ pkgs, hostParams, userParams, ... }:
let
  phockup = pkgs.callPackage ../../pkgs/phockup {};
in
{

  home-manager.users.${userParams.username} = {
    _module.args.hostParams = hostParams;
    _module.args.userParams = userParams;

    # ---------------------------------------------------------------------------
    # Host-specific user packages
    # ---------------------------------------------------------------------------

    imports = [
      ../../home/profiles/aruba-shell.nix
      ../../home/profiles/protonmail-bridge.nix
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        phockup
      ];
    };
  };
}
