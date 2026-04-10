# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  dell-dock-udev-rules = pkgs.callPackage ../../../pkgs/dell-dock-udev-rules {};
in
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "21.11"; # Did you read the comment?
  system.stateVersion = "23.11"; # Did you read the comment?

  nixcfg = {
    desktop = {
      pipewire.enable = true;
      fonts.enable = true;
    };
    networking = {
      mullvad.enable = true;
      kdeconnect.enable = true;
      wireless.enable = true;
      captive-portal.enable = true;
      exclusive-lan.enable = true;
      connection-sharing.enable = true;
    };
    hardware = {
      gfx-nvidia.enable = true;
      gfx-intel.enable = true;
      laptop.enable = true;
      udev-rules.enable = true;
      spacenavd.enable = true;
    };
    programs = {
      appimage.enable = true;
      android.enable = true;
      dell-dcc.enable = true;
      flatpak.enable = true;
      flox.enable = true;
    };
    services = {
      waydroid.enable = true;
      nfs-mounts.enable = true;
      virtual-machines.enable = true;
    };
  };

  imports =
    [
      # device specific
      ./hardware-configuration.nix

      # user specific
      ./user.nix

      # display
      ./kanshi.nix
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

  boot.blacklistedKernelModules = [
    ## SD card reader causing the following error with newer kernels, so disable it:
    ##   "nvme unable to change power state from d3cold to d0, device inaccessible"
    ## See: https://bbs.archlinux.org/viewtopic.php?id=288140
    ## See: https://bbs.archlinux.org/viewtopic.php?id=288095
    "rtsx_pci"
    "rtsx_pci_sdmmc"

    ## From: https://github.com/NixOS/nixos-hardware/blob/master/common/pc/default.nix
    "ath3k"
  ];

  ## Take latest kernel rather than default
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

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

  # Rename dock interface to dock_eth0 instead of the crazy default name;
  services.udev.packages = [ dell-dock-udev-rules ];

  networking = {
    hostId = "39ed170e";

    networkmanager = {
      enable = true;
      wifi = {
        # Use iwd backend for better roaming behavior and auto-connect
        backend = "iwd";
        powersave = false;
        scanRandMacAddress = false;
      };
      # If not set to unmanaged, NetworkManager-wait-online.service will fail
      # @TODO: How to use unmanaged wireguard?
      unmanaged = [
        "wg0"
      ];
    };
    wireless = {
      # Disable wpa_supplicant (using iwd instead)
      enable = false;
      iwd = {
        enable = true;
        settings = {
          General = {
            # Enable network configuration through iwd
            EnableNetworkConfiguration = false;
          };
          Settings = {
            # Auto-connect to known networks
            AutoConnect = true;
          };
        };
      };
    };
  };

  # Enable fingerprint reading daemon.
  # services.fprintd.enable = true;
  # security.pam.services.login.fprintAuth = true;
  # security.pam.services.xscreensaver.fprintAuth = true;

  networking.firewall = {
    allowedUDPPorts = [ 5258 ];
    allowedTCPPorts = [ 5258 ];
  };

  programs.captive-browser = {
    enable = true;
    interface = "wlp0s20f3";
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
      oci-containers.backend = config.hostParams.containers.backend;
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
    if config.hostParams.containers.backend == "podman" then
      lib.recursiveUpdate baseConfig podmanConfig
    else
      lib.recursiveUpdate baseConfig dockerConfig
  );

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  # Enable power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
  };

  powerManagement.cpuFreqGovernor = "performance";

  boot.kernelParams = [
    # Disables discrete Nvidia GPU when not in use
    # Must use bbwsitch or offloading to use GPU
    # "acpi_rev_override=1"

    # Disables DisplayPort Multi-Stream Transport which allows daisychaining monitors,
    # but also causes external monitors not to wake up when waking from sleep.
    "i915.enable_dp_mst=0"

    ## ALSO need to disable C-States in BIOS to prevent problems with monitor wake up
    ## when resuming from sleep while docked.
    ## TODO: Determine whether this causes more battery drain while undocked and asleep.
    ## To see if enabled:
    ##
    ##   cctk --CStatesCtrl

    ## From: https://github.com/NixOS/nixos-hardware/blob/master/common/cpu/intel/kaby-lake/default.nix
    "i915.enable_fbc=1"
    "i915.enable_psr=2"
  ];

  # https://discourse.nixos.org/t/nixos-23-11-thermald-not-working/36317/3
  # Addresses "stack smashing detected" startup error
  # services.thermald.package = pkgs.thermald.overrideAttrs (old: {
  #   patches = (old.patches or [] ) ++ [(builtins.fetchurl {
  #     url = "https://patch-diff.githubusercontent.com/raw/intel/thermal_daemon/pull/422.patch";
  #     sha256 = "1xqv9hn06h8zmf5p8s1nm7xy89zjcgban8rvzw8b2w1ya20lq08r";
  #   })];
  # });

  ## From: https://github.com/NixOS/nixos-hardware/blob/master/common/pc/laptop/default.nix
  # Gnome 40 introduced a new way of managing power, without tlp.
  # However, these 2 services clash when enabled simultaneously.
  # https://github.com/NixOS/nixos-hardware/issues/260
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;


  # @TODO: TEMPORARY - Just testing to see if this has an effect on performance
  #        It works, but this may be dangerous as the laptop could overheat and catch fire
  services.thermald.enable = lib.mkForce false;

  # --------------------------------------------------------------------------------------
  # Packages
  # --------------------------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    # podman tools
    conmon
    runc

    # Proton for Steam
    protonup-ng
  ];
}

