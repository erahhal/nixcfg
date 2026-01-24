# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, userParams, ... }:
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  imports = [
    # Standard
    ../../home/user.nix
    ../../home/desktop.nix
    ../../profiles/common.nix
    ../../profiles/appimage.nix
    ../../profiles/desktop.nix
    ../../profiles/pipewire.nix
    ../../profiles/snapcast.nix
    ../../profiles/wireless.nix

    # device specific
    ./disk-config-btrfs.nix
    ./hardware-configuration.nix
    ../../profiles/android.nix
    ../../profiles/exclusive-lan.nix
    # ../../profiles/jovian.nix
    ../../profiles/laptop-hardware.nix
    # ../../profiles/steam.nix

    # host specific
    ../../profiles/homefree.nix
    ../../profiles/mullvad.nix
    # ../../profiles/ollama.nix
    # ../../profiles/tailscale.nix
    # ../../profiles/thinkpad-dock-udev-rules.nix
    ../../profiles/totp.nix
    ../../profiles/udev.nix
    ../../profiles/waydroid.nix
    ../../profiles/wireguard.nix
    ## Only needed if the docker version needs to be overridden for some reason
    # ../../overlays/docker.nix
    ../../overlays/bcompare-beta.nix
    ../../overlays/chromium-based-apps.nix
    ./virtualization.nix

    # user specific
    ./user.nix

    # Display config
    ./kanshi.nix
    ./niri.nix
    ./sway.nix

    # Temporary
    # ../../profiles/nfs-mounts.nix

    ../../profiles/kdeconnect.nix
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vmware-workstation = pkgs.symlinkJoin {
      name = "vmware-workstation-wrapped";
      paths = [ pkgs.vmware-workstation.unwrapped or pkgs.vmware-workstation ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # Find all executables in the VMware package
        find $out/bin -type f -executable 2>/dev/null | while read -r exe; do
          if [ -f "$exe" ] && [ -x "$exe" ] && [ ! -L "$exe" ]; then
            # Move the original executable
            mv "$exe" "$exe.unwrapped"

            # Create a wrapper that sets GDK_DPI_SCALE
            makeWrapper "$exe.unwrapped" "$exe" \
              --set GDK_DPI_SCALE "0.75"
          fi
        done

        # Also handle any executables in libexec or other locations
        if [ -d "$out/libexec" ]; then
          find "$out/libexec" -type f -executable 2>/dev/null | while read -r exe; do
            if [ -f "$exe" ] && [ -x "$exe" ] && [ ! -L "$exe" ]; then
              mv "$exe" "$exe.unwrapped"
              makeWrapper "$exe.unwrapped" "$exe" \
                --set GDK_DPI_SCALE "0.75"
            fi
          done
        fi

        # Handle any other potential executable locations
        for dir in lib share; do
          if [ -d "$out/$dir" ]; then
            find "$out/$dir" -name "vmware*" -o -name "vmplayer*" | while read -r file; do
              # Only process if it's a regular file, executable, and not a symlink
              if [ -f "$file" ] && [ -x "$file" ] && [ ! -L "$file" ]; then
                # Check if it's actually an executable (has shebang or is binary)
                if file "$file" | grep -q -E "(executable|script)"; then
                  mv "$file" "$file.unwrapped"
                  makeWrapper "$file.unwrapped" "$file" \
                    --set GDK_DPI_SCALE "0.75"
                fi
              fi
            done
          fi
        done
      '';
    };
  };


  # Needed to setup passwords
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNvmGn1/uFnfgnv5qsec0GC04LeVB1Qy/G7WivvvUZVBBDzp8goe1DsE8M8iqnBSin56gQZDWsd50co2MbFAWuqH2HxY7OGay7P/V2q+SziTYFva85WGl84qWvYMmdB+alAFBT3L4eH5cegC5NhNp+OGsQuq32RdojgXXQt6vyZnaOypuz90k3rqV6Rt+iBTLz6VziasCLcYydwOvi9f1q6YQwGPLKaupDrV6gxvoX9bXLdopqwnXPSE/Eqczxgwc3PefvAJPSd6TOqIXvbtpv/B3Evt5SPe2gq+qASc5K0tzgra8KAe813kkpq4FuKJzHbT+EmO70wiJjru7zMEhd erahhal@nfml-erahhalQFL"
  ];
  users.users.${userParams.username}.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNvmGn1/uFnfgnv5qsec0GC04LeVB1Qy/G7WivvvUZVBBDzp8goe1DsE8M8iqnBSin56gQZDWsd50co2MbFAWuqH2HxY7OGay7P/V2q+SziTYFva85WGl84qWvYMmdB+alAFBT3L4eH5cegC5NhNp+OGsQuq32RdojgXXQt6vyZnaOypuz90k3rqV6Rt+iBTLz6VziasCLcYydwOvi9f1q6YQwGPLKaupDrV6gxvoX9bXLdopqwnXPSE/Eqczxgwc3PefvAJPSd6TOqIXvbtpv/B3Evt5SPe2gq+qASc5K0tzgra8KAe813kkpq4FuKJzHbT+EmO70wiJjru7zMEhd erahhal@nfml-erahhalQFL"
  ];


  # --------------------------------------------------------------------------------------
  # Nix
  # --------------------------------------------------------------------------------------

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" "nixos-config=/home/${userParams.username}/Code/nixcfg" ];

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

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    ## attempt to get rid of "rpfilter drop" messages in dmesg, which may be causing intermittent connectivity issues
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  time.timeZone = config.hostParams.system.timeZone;

  ## Fixes microphone
  ## See: https://askubuntu.com/questions/1283440/how-to-fix-ubuntu-incorrectly-seeing-the-internal-microphone-as-an-unplugged-h
  # boot.blacklistedKernelModules = [ "snd-soc-dmic" "snd-acp3x-rn" "snd-acp3x-pdm-dma" ];

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = true;
  ## @TODO: Any ramifications of this?
  systemd.network.wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  ## Change mac randomly on connection
  sec.macchanger = {
    enable = false;
    devices = [
      ## Real: E4:60:17:0F:28:C3
      "wlp0s20f3"
    ];
  };

  ## Attempt to address wifi connectivity issues
  # boot.extraModprobeConfig = ''
  #   options iwlwifi power_save=0
  #   options iwlmvm power_scheme=1
  # '';

  networking = {
    hostName = "nflx-erahhal-p16";
    useNetworkd = false;
    networkmanager = {
      enable = true;
      # Wifi power settings - do not remove
      #   - Either disabling wifi powersave here, or adding
      #     the kernel modules and params below fixed an intermittent
      #     hard freeze when on battery.
      wifi = {
        # Use iwd backend for better roaming behavior and auto-connect
        backend = "iwd";
        powersave = false;
        scanRandMacAddress = false;
      };
      ## When NtworkManager-wait-online.service is enabled, having wg0
      ## as a managed interface may interfere with the service coming up.
      # unmanaged = [
      #   "wg0"
      # ];
    };
    wireless = {
      # Disable wpa_supplicant (using iwd instead)
      enable = false;
      # iwd = {
      #   enable = true;
      #   settings = {
      #     General = {
      #       # Enable network configuration through iwd
      #       EnableNetworkConfiguration = false;
      #     };
      #     Settings = {
      #       # Auto-connect to known networks
      #       AutoConnect = true;
      #     };
      #   };
      # };
    };
    ## Don't include this line - it will add an additional default route.
    ## It's not necessary.
    # interfaces."wlp0s20f3".useDHCP = true;
  };

  services.resolved = {
    enable = true;
    settings.Resolve.DNSSEC = "false";
  };

  programs.captive-browser = {
    enable = true;
    interface = "wlp0s20f3";
  };

  ## Sound support
  hardware.enableAllFirmware = true;

  # Enable fingerprint reading daemon.
  services.fprintd.enable = false;
  security.pam.services.login.fprintAuth = false;
  security.pam.services.xscreensaver.fprintAuth = false;

  services.smokeping = {
    enable = false;
    hostName = "${config.hostParams.hostName}.lan";
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
      host = nas.lan
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
      7002
      7001
      7101
    ];
    trustedInterfaces = [ "docker0" "br-+" ];
  };


  services.flatpak.enable = true;

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
    ## Seems to be needed for suspend to S0 (s2idle) without hanging
    ''acpi_osi="Windows 2022"''

    # Prevent spurious wakeups from a firmware bug where the EC or SMU generates spurious "heartbeat" interrupts during sleep
    "acpi.ec_no_wakeup=1"

    # Prevents dock from waking up laptop right after suspend
    "usbcore.autosuspend=-1"

    ## Settings that supposedly increase gaming perf and prevent HDMI audio dropouts during gaming
    "preempt=full"    # Realitime latency
    "threadirqs"      # forces most interrupt handlers to run in a threaded context, thus reducing input latency.
  ];

  # Disable wakeup sources that cause spurious wakes with Thunderbolt dock
  systemd.services.disable-wakeup-sources = {
    description = "Disable Thunderbolt/USB wakeup sources";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Disable Thunderbolt PCIe root port wakeup (RP09)
      echo disabled > /sys/devices/pci0000:00/0000:00:1d.0/power/wakeup || true

      # Disable USB XHCI controller wakeup
      echo disabled > /sys/devices/pci0000:00/0000:00:14.0/power/wakeup || true

      # Disable ACPI wakeup for XHCI and RP09 (toggle if enabled)
      grep -q "XHCI.*enabled" /proc/acpi/wakeup && echo XHCI > /proc/acpi/wakeup || true
      grep -q "RP09.*enabled" /proc/acpi/wakeup && echo RP09 > /proc/acpi/wakeup || true
    '';
  };

  # # Fix NVIDIA USB4 DP tunnel not resuming after suspend
  # # The NVIDIA driver's proprietary USB4 DP tunnel implementation doesn't properly
  # # re-establish the tunnel after suspend. We need to reload the modules.
  # systemd.services.nvidia-resume-fix = {
  #   description = "Fix NVIDIA USB4 DP tunnel after resume";
  #   after = [ "nvidia-resume.service" "systemd-suspend.service" "systemd-hibernate.service" ];
  #   wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";  # Wait for Thunderbolt link
  #   };
  #   script = ''
  #     # Check if DP outputs are disconnected (indicates failed resume)
  #     if grep -q "disconnected" /sys/class/drm/card0-DP-1/status 2>/dev/null; then
  #       echo "NVIDIA DP tunnel not restored, reloading modules..."
  #
  #       # Remove and reload NVIDIA modules to reset DP tunnel state
  #       ${pkgs.kmod}/bin/rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia 2>/dev/null || true
  #       sleep 1
  #       ${pkgs.kmod}/bin/modprobe nvidia
  #       ${pkgs.kmod}/bin/modprobe nvidia_modeset
  #       ${pkgs.kmod}/bin/modprobe nvidia_uvm
  #       ${pkgs.kmod}/bin/modprobe nvidia_drm
  #
  #       echo "NVIDIA modules reloaded"
  #     fi
  #   '';
  # };

  # Enable power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

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
      # CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      # CPU_HWP_ON_AC = "balance_performance";
      # CPU_HWP_ON_BAT = "balance_power";
      # ENERGY_PERF_POLICY_ON_AC = "performance";
      # ENERGY_PERF_POLICY_ON_BAT = "powersave";
      # SATA_LINKPWR_ON_AC = "max_performance";
      # SATA_LINKPWR_ON_BAT = "min_power";
      # PCIE_ASPM_ON_AC = "performance";
      # PCIE_ASPM_ON_BAT = "powersave";

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

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      # The following prevents the battery from charging fully to
      # preserve lifetime. Run `tlp fullcharge` to temporarily force
      # full charge.
      # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
    } // (if config.hostParams.system.thinkpad-battery-charge-to-full then {
      ## START can't be above 99
      START_CHARGE_THRESH_BAT0=99;
      STOP_CHARGE_THRESH_BAT0=100;
      START_CHARGE_THRESH_BAT1=99;
      STOP_CHARGE_THRESH_BAT1=100;
    } else {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 85;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 85;
    });
  };
}

