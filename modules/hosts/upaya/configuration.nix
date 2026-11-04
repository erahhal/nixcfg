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
      enable = true;
      niri.enable = true;
      dms.enable = true;
      pipewire.enable = true;
      fonts.enable = true;
      ## Also pins Chromium/Brave/Electron apps to the Intel iGPU (iHD decode)
      ## on hybrid hosts.
      chromium-based-apps.enable = true;
    };
    networking = {
      ## No tailscale-key secret for this host: first connect is an
      ## interactive `sudo tailscale up` login.
      tailscale.enable = true;
      mullvad.enable = true;
      kdeconnect.enable = true;
      wireless.enable = true;
      wifi-qos.enable = true;
      captive-portal.enable = true;
      exclusive-lan.enable = true;
      connection-sharing.enable = true;
    };
    hardware = {
      gfx-nvidia = {
        enable = true;
        ## GTX 1050 (Pascal): 580 is the last driver branch that supports it.
        driver = "legacy_580";
        ## Every output on the 9560 (panel, HDMI, Thunderbolt DP) is wired to
        ## the Intel iGPU, so render there and offload to NVIDIA on demand.
        primeMode = "offload";
      };
      gfx-intel.enable = true;
      laptop.enable = true;
      udev-rules.enable = true;
      spacenavd.enable = true;
    };
    programs = {
      appimage.enable = true;
      android.enable = true;
      totp.enable = true;
      dell-dcc.enable = true;
      flatpak.enable = true;
      flox.enable = true;
      switchyard.enable = true;
    };
    services = {
      waydroid.enable = true;
      nfs-mounts.enable = config.hostParams.services.nfs-mounts.enable;
      virtual-machines.enable = true;
      printers-scanners.enable = true;
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
      # Every niri host imports these: they pass hostParams.desktop.* (Mod+G
      # DDC toggle, lid action, startup-app GPU pinning, EasyEffects, ...)
      # through to nixcfg-niri, plus the shared workspace window rules.
      ../../desktop/niri/user-window-rules.nix
      ../../desktop/niri/user-overrides.nix
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

  ## Root is on ZFS, so the kernel must be one ZFS supports: linuxPackages_latest
  ## is routinely ahead of it (zfs_2_4 is marked broken on 7.3). The default
  ## LTS kernel is always covered. zfs.latestCompatibleLinuxPackages, used here
  ## previously, is deprecated and now just aliases linuxPackages.
  boot.kernelPackages = pkgs.linuxPackages;

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

  # Authorize the ThinkPad Thunderbolt 4 Dock and the P40w-20 daisy-chained
  # behind it. BIOS Thunderbolt security is "User Authorization" and this TB3
  # host has no IOMMU DMA protection, so boltd never authorizes them itself:
  # the display (a DisplayPort tunnel) works, but the dock's USB hub and
  # ethernet (a PCIe tunnel) stay dark. Pinned by unique_id; the monitor sits
  # under the dock in sysfs, so udev runs the dock's add event first.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{unique_id}=="be030080-0150-5c8c-8116-21936af43803", ATTR{authorized}=="0", ATTR{authorized}="1"
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{unique_id}=="af030080-0180-848c-0121-941ccda2400b", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';

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
    # iwd's 80-iwd.link keeps the kernel name, so the card is wlan0 (it was
    # wlp2s0 under wpa_supplicant).
    interface = "wlan0";
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
  # powertop's auto-tune fights TLP: it re-enables WiFi power save and USB
  # autosuspend (laggy USB input) behind TLP's back. TLP handles it all.
  powerManagement = {
    enable = true;
    powertop.enable = false;
  };

  # This host cannot hibernate: the ZFS module adds `nohibernate`, and swap is
  # re-keyed every boot (randomEncryption). upower falls back to PowerOff
  # anyway; state it rather than ask for an action that can't happen.
  services.upower = {
    enable = true;
    criticalPowerAction = "PowerOff";
  };

  ## No cpuFreqGovernor = "performance" here: under intel_pstate that pins the
  ## cores at max clocks even when idle, and on this chassis (CPU and GPU share
  ## one cooler) the extra heat is what makes it throttle under real load.
  ## intel_pstate's "powersave" is the dynamic HWP governor, not a slow mode;
  ## responsiveness comes from the energy/perf policy set via TLP below.

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

    ## i915.enable_fbc=1 / i915.enable_psr=2 come from nixos-hardware's
    ## kaby-lake module (imported via dell-xps-15-9560).

    ## Kaby Lake is hit by nearly every CPU side-channel bug, and the combined
    ## fixes (KPTI for Meltdown, MDS buffer clearing, retpolines, ...) slow
    ## anything syscall- or context-switch-heavy -- builds, browsers, I/O --
    ## by a noticeable margin on this generation. Trade-off accepted: these
    ## attacks need code already running locally (incl. a browser's JS).
    "mitigations=off"

    ## Let the kernel resize PCI bridge windows the firmware sized too small.
    ## Behind the ThinkPad TB4 Dock, the bridge to the P40w-20's USB hub (where
    ## the KVM-switched keyboard/mouse live) fails with "bridge window ...
    ## can't assign; no space" and "devices behind bridge are unusable because
    ## [bus 0d] cannot be assigned". Thunderbolt here is BIOS-assisted (_OSC
    ## keeps PCIeHotplug), so the firmware's single range is all there is.
    ## Trial fix; see https://bugs.launchpad.net/bugs/1950780.
    "pci=realloc"
  ];

  ## The firmware advertises a TPM 2.0 (ACPI TPM2 / MSFT0101) that tpm_tis
  ## fails to probe ("error -1"), and tpm2.target then waits 90s for
  ## /dev/tpm0 + /dev/tpmrm0 on every boot and every switch (via
  ## sysinit-reactivation.target). Nothing here uses a TPM, so drop the units.
  systemd.tpm2.enable = false;
  boot.initrd.systemd.tpm2.enable = false;

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
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      # WiFi power save causes latency spikes and drops; NetworkManager
      # already has wifi.powersave = false, keep TLP from undoing it.
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";
    };
  };


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

