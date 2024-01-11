{ config, pkgs, inputs, system, hostParams, userParams, self, ... }:

let
  # Prevents disconnected mounts from hanging system
  nfs3Options = [ "nfsvers=3" ];
  nfs4Options = [ "nfsvers=4" ];
in
{
  services.rpcbind.enable = true;

  services.nfs = {
    idmapd.settings = {
      General = {
        # Facilitates mapping users on an NFS4 server to the local machine
        # Domain needs to be the same on the server and here.

        # DOESN'T CURRENTLY WORK because default authentication on the server
        # is "sec=sys", which uses RPC behind the scenes which uses unmapped
        # UID/GID for auth.  ID mapping only works with Kerberos.

        # See:
        # https://dfusion.com.au/wiki/tiki-index.php?page=Why+NFSv4+UID+mapping+breaks+with+AUTH_UNIX
        Domain = "rahh.al";

        # To solve this, the user of this host has been mapped to
        # an ID that matches the one on the NFS server.
      };
    };
  };

  fileSystems."/mnt/ellis" = {
    device = "10.0.0.42:/volume1/ellis";
    fsType = "nfs";
    # mount when share first used rather than at start, and disconnect after timeout
    options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/family-files" = {
    device = "10.0.0.42:/volume1/family-files";
    fsType = "nfs";
    # mount when share first used rather than at start, and disconnect after timeout
    options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/nas-home" = {
    device = "10.0.0.42:/volume1/homes";
    fsType = "nfs";
    # mount when share first used rather than at start, and disconnect after timeout
    options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
}
