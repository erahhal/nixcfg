# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, userParams, hostParams, ... }:

let
  thinkpad-dock-udev-rules = pkgs.callPackage ../../pkgs/thinkpad-dock-udev-rules { };
in
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  imports =
    [
      # Standard
      ../../home/user.nix
      ../../home/desktop.nix
      ../../profiles/common.nix
      ../../profiles/desktop.nix
      ../../profiles/pipewire.nix
      ../../profiles/wireless.nix

      # device specific
      ./hardware-configuration.nix
      ../../profiles/android.nix
      ../../profiles/exclusive-lan.nix
      ../../profiles/gfx-intel.nix
      ../../profiles/laptop-hardware.nix
      ../../profiles/steam.nix

      # host specific
      ../../profiles/mullvad.nix
      ../../profiles/totp.nix
      ../../profiles/udev.nix
      ../../profiles/waydroid.nix
      ../../profiles/wireguard.nix
      # ../../profiles/bambu-studio.nix
      ## Only needed if the docker version needs to be overridden for some reason
      # ../../overlays/docker.nix
      # ../../overlays/bcompare-beta.nix
      ./virtualization.nix

      # user specific
      ./user.nix

      # Display config
      ./kanshi.nix
      ./launch-apps-config-sway.nix
      ./launch-apps-config-hyprland.nix

      # Temporary
      # ../../profiles/nfs-mounts.nix
    ];

  # --------------------------------------------------------------------------------------
  # Nix
  # --------------------------------------------------------------------------------------

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" "nixos-config=/home/Code/${userParams.username}/nixcfg" ];

  # --------------------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------------------

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    # Set font size early
    efi = {
      canTouchEfiVariables = true;
    };
  };

  ## Latest kernel doesn't always work with ZFS
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  ## Latest ZFS compatible kernel has problems with dual external displays
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  time.timeZone = hostParams.timeZone;

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = true;
  ## @TODO: Any ramifications of this?
  systemd.network.wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  ## Change mac randomly on connection
  sec.macchanger = {
    enable = true;
    devices = [
      ## Real: E4:60:17:0F:28:C3
      "wlp0s20f3"
    ];
  };

  # Rename dock interface to dock_eth0 instead of the crazy default name;
  services.udev.packages = [ thinkpad-dock-udev-rules ];

  networking = {
    hostName = "nflx-erahhal-x1c";
    useNetworkd = true;
    networkmanager = {
      enable = true;
      # Wifi power settings - do not remove
      #   - Either disabling wifi powersave here, or adding
      #     the kernel modules and params below fixed an intermittent
      #     hard freeze when on battery.
      wifi = {
        # backend = "iwd";
        # powersave = false;
        scanRandMacAddress = false;
      };
      ## When NtworkManager-wait-online.service is enabled, having wg0
      ## as a managed interface may interfere with the service coming up.
      # unmanaged = [
      #   "wg0"
      # ];
    };
    wireless = {
      # Disable wpa_supplicant
      enable = false;
    };
    ## Don't include this line - it will add an additional default route.
    ## It's not necessary.
    # interfaces."wlp0s20f3".useDHCP = true;
  };

  # Enable fingerprint reading daemon.
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xscreensaver.fprintAuth = true;

  services.smokeping = {
    enable = false;
    hostName = "localhost";
    targetConfig = ''
      probe = FPing
      menu = Top
      title = Network Latency Grapher
      remark = Welcome to SmokePing
      + google
      menu = Google
      title = google Network
      ++ googlesite
      host = google.com
      ++ googledns
      host = 8.8.8.8
      + netflix
      menu = Netflix
      title = Netlix Network
      ++ vpn
      host = lt.ovpn.netflix.net
      + home
      menu = Home
      title = Home Network
      ++ nasserver
      host = nas.localdomain
    '';
  };

  networking.firewall = {
    allowedUDPPorts = [
    ];
    allowedTCPPorts = [
      # Common docker development port
      80
      3000
      8080
    ];
  };

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  services.syslogd.enable = true;

  # Despite the generic name, this is Lenovo specific
  ## Doesn't currently work with x1c CPU
  services.throttled.enable = false;

  # Thinkpad settings

  # Kernel settings - do not remove
  #   - Either adding these kernel modules and params,
  #     or turning off power saving on wifi fixed an intermittent
  #     hard freeze when on battery.
  # boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  # boot.kernelModules = [ "thinkpad-acpi" "acpi_call" ];
  # boot.initrd.kernelModules = [ "thinkpad-acpi" "acpi_call" ];
  boot.kernelParams = [
    "msr.allow_writes=on"
    "cpuidle.governor=teo"
    # "usbcore.use_both_schemes=y"
    # "usbcore.autosuspend=-1"
  ];

  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
  };

  # Thinkpad power and performance management
  # https://linrunner.de/tlp/settings/usb.html
  services.tlp = {
    enable = true;
    settings = {
      # Control battery feature drivers:
      # NATACPI_ENABLE = 1;
      # TPACPI_ENABLE = 1;
      # TPSMAPI_ENABLE = 1;

      # # Sometimes dock doesn't unuspend, causing USB to stop working
      # USB_AUTOSUSPEND = 0;
      # USB_DENYLIST = "17ef:30b4 17ef:30b5 17ef:30b6 17ef:30b7 17ef:30b8 17ef:30b9 17ef:30ba 17ef:30bb";

      ## "performance" severely degrades IO performance on X1C. Leave as default ("powersave").
      ## Options are "performance" and "powersave" when intel_pstate is active
      ## cat /sys/devices/system/cpu/intel_pstate/status
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      # CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Supposedly gets rid of stutter in Hyprland
      # https://wiki.hyprland.org/Configuring/Perfomance/
      INTEL_GPU_MIN_FREQ_ON_AC = 500;
      INTEL_GPU_MIN_FREQ_ON_BAT = 500;

      # 100 being the maximum, limit the speed of my CPU to reduce
      # heat and decrease battery usage:
      CPU_MAX_PERF_ON_AC = 100;
      CPU_BOOST_ON_AC = 1;

      CPU_MAX_PERF_ON_BAT = 50;
      # Only works if intel_pstate is active
      CPU_BOOST_ON_BAT = 0;

      ## High-perf battery settings
      # CPU_MAX_PERF_ON_BAT = 100;
      # CPU_BOOST_ON_BAT = 1;

      # The following prevents the battery from charging fully to
      # preserve lifetime. Run `tlp fullcharge` to temporarily force
      # full charge.
      # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds

      START_CHARGE_THRESH_BAT0 = 60;
      STOP_CHARGE_THRESH_BAT0 = 85;
      START_CHARGE_THRESH_BAT1 = 60;
      STOP_CHARGE_THRESH_BAT1 = 85;

      ## High charge settings

      # START_CHARGE_THRESH_BAT0=85;
      # STOP_CHARGE_THRESH_BAT0=95;
      # START_CHARGE_THRESH_BAT1=85;
      # STOP_CHARGE_THRESH_BAT1=95;

      ## Travel settings
      ## START can't be above 99

      # START_CHARGE_THRESH_BAT0=99;
      # STOP_CHARGE_THRESH_BAT0=100;
      # START_CHARGE_THRESH_BAT1=99;
      # STOP_CHARGE_THRESH_BAT1=100;
    };
  };
}

