{ pkgs, userParams, ... }:

let
  vdhcoapp = pkgs.callPackage ../../pkgs/vdhcoapp {};
in
{
  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    home = {
      packages = with pkgs; [
        vdhcoapp
      ];
    };

    home.activation.vdhcoapp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      net.downloadhelper.coapp install
      mkdir -p /home/${userParams.username}/.mozilla/native-messaging-hosts
      cp -rf /usr/lib/mozilla/native-messaging-hosts/net.downloadhelper.coapp.json /home/${userParams.username}/.mozilla/native-messaging-hosts
      rm -rf /usr/lib/mozilla/native-messaging-hosts/net.downloadhelper.coapp.json
    '';
  };
}
