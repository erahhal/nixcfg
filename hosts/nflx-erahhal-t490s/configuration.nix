# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, hostParams, recursiveMerge, ... }:

let
  thinkpad-dock-udev-rules = pkgs.callPackage ../../pkgs/thinkpad-dock-udev-rules { };
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
      ../../profiles/wireless.nix

      # device specific
      ./hardware-configuration.nix
      # ../../modules/rkvm.nix
      ../../profiles/android.nix
      ../../profiles/exclusive-lan.nix
      ../../profiles/gfx-intel.nix
      ../../profiles/laptop-hardware.nix

      # host specific
      ../../profiles/mullvad.nix
      ../../profiles/totp.nix
      ../../profiles/udev.nix
      ../../profiles/virtual-machines.nix
      ../../profiles/waydroid.nix
      ../../profiles/wireguard.nix
      ## Only needed if the docker version needs to be overridden for some reason
      # ../../overlays/docker.nix

      # user specific
      ./user.nix

      # Display config
      ./kanshi.nix
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

  ## Take latest kernel rather than default
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --------------------------------------------------------------------------------------
  # File system
  # --------------------------------------------------------------------------------------

  # Set up LUKS requirements
  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/0d4b364c-9873-4238-a36c-0c36ef044429";

  # Allow trim on SSD
  boot.initrd.luks.devices.crypted.allowDiscards = true;

  # Supposedly better for the SSD.
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  time.timeZone = hostParams.timeZone;

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = true;

  # Rename dock interface to dock_eth0 instead of the crazy default name;
  services.udev.packages = [ thinkpad-dock-udev-rules ];

  ## Disable IPv6 - these don't work
  # boot.kernel.sysctl = {
  #   "net.ipv6.conf.all.disable_ipv6" = 1;
  #   "net.ipv6.conf.default.disable_ipv6" = 1;
  #   "net.ipv6.conf.lo.disable_ipv6" = 1;
  # };
  # networking.enableIPv6 = false;

  networking = {
    hostName = "nflx-erahhal-t490s";
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
      # If not set to unmanaged, NetworkManager-wait-online.service will fail
      # @TODO: How to use unmanaged wireguard?
      unmanaged = [
        "wg0"
      ];
    };
    wireless = {
      enable = false;
      interfaces = [ "wlan0" "wlp0s20f3" ];
      userControlled.enable = true;
    };
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    interfaces = {
      # Built-in interface
      "enp0s31f6".useDHCP = true;
      # Named in pkgs/thinkpad-dock-udev-rules/default.nix
      "dock_eth0".useDHCP = true;
      # Default name of thinkpad dock interface
      "enp7s0u1u4u4u3".useDHCP = true;
      # Wifi
      "wlan0" = {
        useDHCP = true;
      };
      "wlp0s20f3" = {
        useDHCP = true;
      };
    };
  };

  # Enable fingerprint reading daemon.
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xscreensaver.fprintAuth = true;

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
          server = "localhost:5258"
          certificate-path = "${config.age.secrets.rkvm-certificate.path}"
        '';
      };
      autoStart = true;
    };
  };
  */

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
      host = 10.0.0.93
    '';
  };

  # Enable containers
  virtualisation = (
    let
      baseConfig = {
        oci-containers.backend = hostParams.containerBackend;
        containers = {
          enable = true;
        };
      };
      podmanConfig = {
        podman = {
          enable = true;
          dockerCompat = true;
          extraPackages = [ pkgs.zfs ];
        };
      };
      dockerConfig = {
        docker = {
          enable = true;
          daemon.settings = {
            "ipv6" = false;
            "exec-opts" = [ "native.cgroupdriver=systemd" ];
            "features" = { "buildkit" = true; };
            "experimental" = true;
            "default-cgroupns-mode" = "host";
            "cgroup-parent" = "docker.slice";
            "mtu" = 1460;
          };
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

  # Despite the generic name, this is Lenovo specific
  services.throttled.enable = true;

  # Thinkpad settings

  # Kernel settings - do not remove
  #   - Either adding these kernel modules and params,
  #     or turning off power saving on wifi fixed an intermittent
  #     hard freeze when on battery.
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  boot.kernelModules = [ "thinkpad-acpi" "acpi_call" ];
  boot.initrd.kernelModules = [ "thinkpad-acpi" "acpi_call" ];
  boot.kernelParams = [
    "msr.allow_writes=on"
    "cpuidle.governor=teo"
  ];

  # Thinkpad power and performance management
  # https://linrunner.de/tlp/settings/usb.html
  services.tlp = {
    enable = true;
    settings = {
      # Control battery feature drivers:
      NATACPI_ENABLE = 1;
      TPACPI_ENABLE = 1;
      TPSMAPI_ENABLE = 1;

      # USB_AUTOSUSPEND = 1;
      # # Sometimes dock doesn't unuspend, causing USB to stop working
      # USB_DENYLIST = "17ef:30b4 17ef:30b5 17ef:30b6 17ef:30b7 17ef:30b8 17ef:30b9 17ef:30ba 17ef:30bb";

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # 100 being the maximum, limit the speed of my CPU to reduce
      # heat and decrease battery usage:
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MAX_PERF_ON_BAT = 50;

      # The following prevents the battery from charging fully to
      # preserve lifetime. Run `tlp fullcharge` to temporarily force
      # full charge.
      # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds

      # START_CHARGE_THRESH_BAT0 = 60;
      # STOP_CHARGE_THRESH_BAT0 = 85;
      # START_CHARGE_THRESH_BAT1 = 60;
      # STOP_CHARGE_THRESH_BAT1 = 85;

      # ## High charge settings
      # START_CHARGE_THRESH_BAT0=85;
      # STOP_CHARGE_THRESH_BAT0=95;
      # START_CHARGE_THRESH_BAT1=85;
      # STOP_CHARGE_THRESH_BAT1=95;

      ## Travel settings
      ## START can't be above 99
      START_CHARGE_THRESH_BAT0=99;
      STOP_CHARGE_THRESH_BAT0=100;
      START_CHARGE_THRESH_BAT1=99;
      STOP_CHARGE_THRESH_BAT1=100;
    };
  };
}

