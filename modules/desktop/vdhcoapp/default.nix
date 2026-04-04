{ pkgs, userParams, ... }:

let
  vdhcoapp = pkgs.callPackage ../../../pkgs/vdhcoapp {};
in
{
  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    home = {
      packages = [
        vdhcoapp
      ];
    };

    home.activation.vdhcoapp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p /home/${userParams.username}/.mozilla/native-messaging-hosts
      # This is the crucial update across builds, as it points to a different nix store path with each update
      cp -rf ${vdhcoapp}/lib/mozilla/native-messaging-hosts/net.downloadhelper.coapp.json /home/${userParams.username}/.mozilla/native-messaging-hosts
    '';
  };
}
