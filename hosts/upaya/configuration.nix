# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, hostParams, recursiveMerge, ... }:

let
  dell-dock-udev-rules = pkgs.callPackage ../../pkgs/dell-dock-udev-rules {};
in
{
  imports =
    [
      # Standard
      ../../home/user.nix
      ../../home/desktop.nix
      ../../profiles/common.nix
      ../../profiles/desktop.nix
      ../../profiles/pipewire.nix
      ../../profiles/steam-nvidia-desktop.nix
      ../../profiles/wireless.nix

      # device specific
      ./hardware-configuration.nix
      # ../../modules/rkvm.nix
      ../../profiles/android.nix
      ../../profiles/exclusive-lan.nix
      ../../profiles/gfx-nvidia.nix
      ../../profiles/dell-dcc.nix
      ../../profiles/laptop-hardware.nix

      # host specific
      ../../profiles/mullvad.nix
      ../../profiles/nfs-mounts.nix
      ../../profiles/udev.nix
      ../../profiles/waydroid.nix
      ../../profiles/wireguard.nix
      ../../profiles/virtual-machines.nix

      # user specific
      ./user.nix

      # Display config
      ./launch-apps-config.nix
    ];

  # --------------------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------------------

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      # Use maximum resolution in systemd-boot for hidpi
      consoleMode = "max";
    };
    # Set font size early
    efi = {
      canTouchEfiVariables = true;
    };
  };

  ## SD card reader causing the following error with newer kernels, so disable it:
  ##   "nvme unable to change power state from d3cold to d0, device inaccessible"
  ## See: https://bbs.archlinux.org/viewtopic.php?id=288140
  ## See: https://bbs.archlinux.org/viewtopic.php?id=288095
  boot.blacklistedKernelModules = [ "rtsx_pci" "rtsx_pci_sdmmc" ];

  ## Take latest kernel rather than default
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # --------------------------------------------------------------------------------------
  # File system
  # --------------------------------------------------------------------------------------

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  ## Needed to boot with latest kernel
  # boot.zfs.enableUnstable = true;

  # Remote unlock
  boot.initrd.network = {
    # @TODO: setup
  };

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

  swapDevices = [
    {
      device = "/dev/nvme0n1p2";
      randomEncryption = true;
    }
  ];

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  time.timeZone = hostParams.timeZone;

  # Rename dock interface to dock_eth0 instead of the crazy default name;
  services.udev.packages = [ dell-dock-udev-rules ];

  hardware.sane = {
    enable = true;
    brscan5 = {
      enable = true;
      netDevices = {
        brother = {
          model = "MFC-L2710DW";
          nodename = "BRW8CC84B1E2FC1";
        };
      };
    };
  };

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = true;
  ## @TODO: Any ramifications of this?
  systemd.network.wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  networking = {
    hostName = hostParams.hostName;
    hostId = "39ed170e";

    useNetworkd = true;
    networkmanager = {
      enable = true;
      wifi = {
        # backend = "iwd";
        # powersave = false;
        scanRandMacAddress = false;
      };
      # If not set to unmanaged, NetworkManager-wait-online.service will fail
      # @TODO: How to use unmanaged wireguard?
      unmanaged = [
        "wg0"
      ];
    };
    wireless = {
      enable = false;
    };

    ## Wireguard
    # firewall = {
    #   allowedUDPPorts = [ 64210 ];
    # };
    # wireguard.interfaces = {
    #   # "wg0" is the network interface name. You can name the interface arbitrarily.
    #   wg0 = {
    #     # Determines the IP address and subnet of the client's end of the tunnel interface.
    #     ips = [ "192.168.2.3/24" ];
    #     listenPort = 64210; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

    #     # Path to the private key file.
    #     privateKeyFile = config.age.secrets.wireguard-private.path;

    #     peers = [
    #       # For a client configuration, one peer entry for the server will suffice.

    #       {
    #         # Public key of the server (not a file path).
    #         publicKey = "EpIitQWn0xHvMj0q8MgKgrDA8lqqm+saDdgk8PwiQXw=";

    #         # Forward all the traffic via VPN.
    #         # allowedIPs = [ "0.0.0.0/0" "::/0" ];

    #         # Or forward only particular subnets
    #         allowedIPs = [ "10.0.0.0/24" "192.168.2.0/24" ];

    #         # Set this to the server IP and port.
    #         endpoint = "rahh.al:64210"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

    #         # Send keepalives every 25 seconds. Important to keep NAT tables alive.
    #         persistentKeepalive = 25;
    #       }
    #     ];
    #   };
    # };
  };

  # Enable fingerprint reading daemon.
  # services.fprintd.enable = true;
  # security.pam.services.login.fprintAuth = true;
  # security.pam.services.xscreensaver.fprintAuth = true;

  networking.firewall = {
    allowedUDPPorts = [ 5258 ];
    allowedTCPPorts = [ 5258 ];
  };

  /*
  services.rkvm = {
    server = {
      enable = true;
      configFile = pkgs.writeTextFile {
        name = "server.toml";
        text = ''
          listen-address = "0.0.0.0:5258"
          # Switch to next client by pressing the left alt key.
          switch-keys = ["LeftAlt"]
          identity-path = "${config.age.secrets.rkvm-identity.path}"
          ## Leave unset if no password is set.
          # identity-password = "123456789"
        '';
      };
      autoStart = true;
    };
  };

  services.rkvm = {
    client = {
      enable = true;
      configFile = pkgs.writeTextFile {
        name = "client.toml";
        text = ''
          server = "nflx-erahhal-t490s-dock:5258"
          certificate-path = "${config.age.secrets.rkvm-certificate.path}"
        '';
      };
      autoStart = false;
    };
  };
  */

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
      };
    };
  in
    if hostParams.containerBackend == "podman" then
      recursiveMerge [ baseConfig podmanConfig ]
    else
      recursiveMerge [ baseConfig dockerConfig ]
  );

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  boot.kernelParams = [
    # Disables discrete Nvidia GPU when not in use
    # Must use bbwsitch or offloading to use GPU
    "acpi_rev_override=1"

    # Disables DisplayPort Multi-Stream Transport which allows daisychaining monitors,
    # but also causes external monitors not to wake up when waking from sleep.
    "i915.enable_dp_mst=0"

    ## ALSO need to disable C-States in BIOS to prevent problems with monitor wake up
    ## when resuming from sleep while docked.
    ## TODO: Determine whether this causes more battery drain while undocked and asleep.
    ## To see if enabled:
    ##
    ##   cctk --CStatesCtrl
  ];

  # --------------------------------------------------------------------------------------
  # Packages
  # --------------------------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    # podman tools
    conmon
    runc

    # Proton for Steam
    protonup
  ];
}

