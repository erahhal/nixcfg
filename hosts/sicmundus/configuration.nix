# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, hostParams, userParams, recursiveMerge, ... }:

let
  fanSettingsScript = pkgs.writeShellScriptBin "fan-settings" ''
    IP=10.0.0.9
    PASSWD="/home/erahhal/.ssh/ilo-passwordfile"
    SSH="${pkgs.openssh}/bin/ssh -o HostKeyAlgorithms=ssh-rsa -o KexAlgorithms=+diffie-hellman-group1-sha1 -o StrictHostKeyChecking=no"

    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan info'

    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan pid 13 lo 1600'
    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan pid 14 lo 1600'
    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan pid 17 lo 1600'
    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan pid 18 lo 1600'
    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan pid 19 lo 1600'
    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan pid 20 lo 1600'

    # This might not be OK
    ${pkgs.sshpass}/bin/sshpass -f "$PASSWD" $SSH Administrator@$IP 'fan p 2 max 63'
  '';
in
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  imports =
    [
      # Standard
      ../../home/user.nix
      ../../modules/hp-ams.nix
      ../../profiles/common.nix

      # device specific
      ./hardware-configuration.nix

      # host specific
      ../../profiles/nfs-mounts.nix
      ../../profiles/udev.nix
      ./backup.nix

      # containers
      ../../containers/authentik.nix
      ../../containers/collabora.nix
      ../../containers/cryptpad.nix
      ../../containers/drawio.nix
      ../../containers/etherpad.nix
      ../../containers/gitea.nix
      ../../containers/grist.nix
      ../../containers/jellyfin.nix
      ../../containers/joplin.nix
      ../../containers/logseq.nix
      ../../containers/mariadb.nix
      ../../containers/minecraft.nix
      ../../containers/minio.nix
      ../../containers/nextcloud.nix
      ../../containers/pinry.nix
      ../../containers/postgres.nix
      ../../containers/redis.nix
      ../../containers/smokeping.nix
      ../../containers/syncthing.nix
      ../../containers/vaultwarden.nix
      ../../containers/wekan.nix
      ../../containers/wikijs.nix
      ../../containers/xbrowsersync.nix

      # ../../containers/librephotos.nix
      ../../containers/photoprism.nix

      # user specific
      ./user.nix
    ];

  # --------------------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------------------

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
    # "Using NixOS on a ZFS root file system might result in the boot error external
    #  pointer tables not supported when the number of hardlinks in the nix store gets
    #  very high. This can be avoided by adding this option"
    copyKernels = true;
  };

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # --------------------------------------------------------------------------------------
  # File system
  # --------------------------------------------------------------------------------------

  # Gets rid of error: "Failed to allocate directory watch: Too many open files"
  # when there are a lot of docker containers
  boot.kernel.sysctl."fs.inotify.max_user_instances" = 512;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  ## Needed to boot with latest kernel
  # boot.zfs.enableUnstable = true;

  services.zfs = {
    trim.enable = true;
    autoScrub = {
      enable = true;
      pools = [ "rpool" ];
    };
    autoSnapshot = {
      enable = true;
      frequent = 8;
      monthly = 1;
    };
  };

  networking.hostId = "e3bfcc8b";

  swapDevices = [
    {
      device = "/dev/sda2";
      randomEncryption = true;
    }
  ];

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  time.timeZone = hostParams.timeZone;

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = true;

  networking = {
    hostName = hostParams.hostName;
    useNetworkd = true;
    networkmanager = {
      enable = true;
    };

    ## This is needed for a fixed IP
    interfaces = {
      ${hostParams.mainInterface} = {
        useDHCP = true;
        ipv4.addresses = [
          { address = "10.0.0.2"; prefixLength = 8; }
        ];
      };
    };
  };

  systemd.services.disable-unused-adapters = {
    enable = true;
    description = "Disable unused adapters to avoid iLO reporting degraded network";
    script = ''
      ${pkgs.iproute2}/bin/ip link set eno1 down
      ${pkgs.iproute2}/bin/ip link set eno2 down
      ${pkgs.iproute2}/bin/ip link set enp4s0f1 down
    '';

    requires = [ "systemd-networkd-wait-online.service" ];
    after = [ "systemd-networkd-wait-online.service" ]; # starts after network is up
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      # Restart = "on-failure";
      # RestartSec = 5;
    };
  };

  services.openiscsi = {
    enable = true;
    name = "sicmundus";
    extraConfig = ''
      DiscoveryAddress = 10.0.0.42
    '';
  };

  # Enable containers
  virtualisation = (
  let
    baseConfig =  {
      oci-containers.backend = hostParams.containerBackend;
      containers = {
        enable = true;
      };
    };
    podmanConfig = {
      containers = {
        storage = {
          settings = {
            storage = {
              driver = "vfs";
              graphroot = "/var/lib/containers/storage";
              runroot = "/run/containers/storage";
            };
          };
        };
      };
      podman = {
        enable = true;
        dockerCompat = true;
        extraPackages = [ pkgs.zfs ];
      };
    };
    dockerConfig = {
      docker = {
        enable = true;
        autoPrune = {
          enable = true;
          flags = [ "-a" "--volumes" ];
          # default frequency: weekly
        };
        daemon.settings = {
          "exec-opts" = ["native.cgroupdriver=systemd"];
          "features" = { "buildkit" = true; };
          "experimental" = true;
          "default-cgroupns-mode" = "host";
          "cgroup-parent" = "docker.slice";
          "mtu" = 1460;
        };
        ## Doesn't seem to be working well - most containers
        ## Don't start.  Could be the subuid and subgid settings below
        ## See:
        ## https://docs.docker.com/engine/security/userns-remap/

        # daemon.settings = {
        #   "userns-remap" = "${userParams.username}:users";
        # };
      };
    };
  in
    if hostParams.containerBackend == "podman" then
      recursiveMerge [ baseConfig podmanConfig ]
    else
      recursiveMerge [ baseConfig dockerConfig ]
  );

  # For userns-remap. Maybe wrong
  environment.etc.subuid = {
    text = ''
      ${userParams.username}:0:1000
      ${userParams.username}:${toString userParams.uid}:65536
    '';
    mode = "0440";
  };

  # For userns-remap. Maybe wrong
  environment.etc.subgid = {
    text = ''
      erahhal:0:100
      erahhal:101:65536
    '';
    mode = "0440";
  };

  # --------------------------------------------------------------------------------------
  # Mounts
  # --------------------------------------------------------------------------------------

  # For mount.cifs, required unless domain name resolution is not needed.
  fileSystems =
  let
    # this line prevents hanging on network split
    automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    options = ["${automount_opts},credentials=${config.age.secrets.homeassistant-samba.path}"];
  in {
    "/mnt/homeassistant-backups" = {
      device = "//ha.localdomain/backup";
      fsType = "cifs";
      options = options;
    };
    "/mnt/homeassistant-config" = {
      device = "//ha.localdomain/config";
      fsType = "cifs";
      options = options;
    };
    "/mnt/homeassistant-addons" = {
      device = "//ha.localdomain/addons";
      fsType = "cifs";
      options = options;
    };
  };

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  # https://support.hpe.com/hpesc/public/docDisplay?docId=emr_na-c04565693
  # https://forum.manjaro.org/t/pcc-cpufreq-initstate-no-such-device-error/14172
  boot.kernelParams = [ "intel_iommu=off" "intel_pstate=active" ];

  systemd.services.fan-settings = {
    enable = true;
    description = "Adjust fans through iLO";
    script = ''
      ${fanSettingsScript}/bin/fan-settings
    '';

    # requires = [ "systemd-networkd-wait-online.service" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-networkd-wait-online.service" ]; # starts after network is up
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  services.hp-ams = {
    enable = true;
  };

  # --------------------------------------------------------------------------------------
  # Packages
  # --------------------------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    # custom
    fanSettingsScript

    # SAMBA
    cifs-utils

    # podman tools
    conmon
    runc

    postgresql
    mariadb
  ];
}

