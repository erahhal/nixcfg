{ config, inputs, lib, pkgs, userParams, ... }:
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  imports =
    [
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
      ../../profiles/tailscale.nix
      ../../profiles/thinkpad-dock-udev-rules.nix
      ../../profiles/totp.nix
      ../../profiles/udev.nix
      ../../profiles/waydroid.nix
      ../../profiles/wireguard.nix
      ## Only needed if the docker version needs to be overridden for some reason
      # ../../overlays/docker.nix
      ../../overlays/bcompare-beta.nix
      ../../overlays/chromium-wayland-ime.nix
      ./virtualization.nix

      # user specific
      ./user.nix

      # Display config
      ./kanshi.nix
      ./launch-apps-config-sway.nix

      ../../profiles/nfs-mounts.nix
      # ../../profiles/smb-mounts.nix
    ];

  # Needed to setup passwords
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNvmGn1/uFnfgnv5qsec0GC04LeVB1Qy/G7WivvvUZVBBDzp8goe1DsE8M8iqnBSin56gQZDWsd50co2MbFAWuqH2HxY7OGay7P/V2q+SziTYFva85WGl84qWvYMmdB+alAFBT3L4eH5cegC5NhNp+OGsQuq32RdojgXXQt6vyZnaOypuz90k3rqV6Rt+iBTLz6VziasCLcYydwOvi9f1q6YQwGPLKaupDrV6gxvoX9bXLdopqwnXPSE/Eqczxgwc3PefvAJPSd6TOqIXvbtpv/B3Evt5SPe2gq+qASc5K0tzgra8KAe813kkpq4FuKJzHbT+EmO70wiJjru7zMEhd erahhal@nfml-erahhalQFL"
  ];
  users.users.${userParams.username}.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNvmGn1/uFnfgnv5qsec0GC04LeVB1Qy/G7WivvvUZVBBDzp8goe1DsE8M8iqnBSin56gQZDWsd50co2MbFAWuqH2HxY7OGay7P/V2q+SziTYFva85WGl84qWvYMmdB+alAFBT3L4eH5cegC5NhNp+OGsQuq32RdojgXXQt6vyZnaOypuz90k3rqV6Rt+iBTLz6VziasCLcYydwOvi9f1q6YQwGPLKaupDrV6gxvoX9bXLdopqwnXPSE/Eqczxgwc3PefvAJPSd6TOqIXvbtpv/B3Evt5SPe2gq+qASc5K0tzgra8KAe813kkpq4FuKJzHbT+EmO70wiJjru7zMEhd erahhal@nfml-erahhalQFL"
  ];

  ## @TODO: Move elsewhere or just get rid of it
  networking.hostId = "8425e349";

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

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  ## Disable swap
  swapDevices = lib.mkForce [ ];

  ## Enable zramswap (must disable swap above)
  ## Supposedly helps with out of memory errors during compilation of big projects
  zramSwap = {
    ## Currently no swap partition configured
    ## @TODO: Can zramswap be used with an encrypted LUKS partition?
    enable = false;
    writebackDevice = "/dev/nvme0n1p2";
  };

  time.timeZone = config.hostParams.system.timeZone;

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = true;
  ## @TODO: Any ramifications of this?
  systemd.network.wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  ## Change mac randomly on connection
  sec.macchanger = {
    enable = false;
    devices = [
      ## Real: NN
      "wlp0s20f3"
    ];
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

  networking = {
    hostName = config.hostParams.system.hostName;
    useNetworkd = true;
    networkmanager = {
      enable = true;
      wifi = {
        # backend = "iwd";
        ## Disabling powersave fixes stability issue with wifi
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
      # Disable wpa_supplicant
      enable = false;
    };
    ## Don't include this line - it will add an additional default route.
    ## It's not necessary.
    # interfaces."wlp0s20f3".useDHCP = true;
  };

  services.resolved = {
    enable = true;
    dnssec = "false";
  };

  programs.captive-browser = {
    enable = true;
    interface = "wlp0s20f3";
  };

  ## Sound support
  hardware.enableAllFirmware = true;

  # Enable fingerprint reading daemon.
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xscreensaver.fprintAuth = true;

  services.smokeping = {
    enable = false;
    hostName = "antikythera.lan";
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
    ];
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
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"

    ## Fixes input lag issue in Hyprland
    ## @TODO: Remove after fixed in kernel
    # "amdgpu.dcdebugmask=0x610"
    "amdgpu.dcdebugmask=0x10"

    "amd_pstate=active"
    "processor=ignore_ppc=1"

    # "msr.allow_writes=on"
    # "cpuidle.governor=teo"

    # "usbcore.use_both_schemes=y"
    "usbcore.autosuspend=-1"
  ];

  ## Make sure CPU runs at max performance
  systemd.services.ryzenadj = {
    description = "Set AMD CPU Power Limits";
    wantedBy = [ "multi-user.target" ];
    after = [ "syslog.target" "systemd-modules-load.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=54000 --fast-limit=65000 --slow-limit=54000 --tctl-temp=95 --vrm-current=150000 --vrmmax-current=150000";
    };
  };

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
      # ------------------------------------------------------------------------------
      # tlp - Parameters for power saving

      # Set to 0 to disable, 1 to enable TLP.
      # Default: 1

      TLP_ENABLE = 1;

      # Control how warnings about invalid settings are issued:
      #   0=disabled,
      #   1=background tasks (boot, resume, change of power source) report to syslog,
      #   2=shell commands report to the terminal (stderr),
      #   3=combination of 1 and 2
      # Default: 3

      #TLP_WARN_LEVEL = 3;

      # Operation mode when no power supply can be detected: AC, BAT.
      # Concerns some desktop and embedded hardware only.
      # Default: <none>

      #TLP_DEFAULT_MODE = "AC";

      # Operation mode select: 0=depend on power source, 1=always use TLP_DEFAULT_MODE
      # Note: use in conjunction with TLP_DEFAULT_MODE=BAT for BAT settings on AC.
      # Default: 0

      #TLP_PERSISTENT_DEFAULT = 0;

      # Power supply classes to ignore when determining operation mode: AC, USB, BAT.
      # Separate multiple classes with spaces.
      # Note: try on laptops where operation mode AC/BAT is incorrectly detected.
      # Default: <none>

      #TLP_PS_IGNORE = "BAT";

      # Seconds laptop mode has to wait after the disk goes idle before doing a sync.
      # Non-zero value enables, zero disables laptop mode.
      # Default: 0 (AC), 2 (BAT)

      DISK_IDLE_SECS_ON_AC = 0;
      DISK_IDLE_SECS_ON_BAT = 2;

      # Dirty page values (timeouts in secs).
      # Default: 15 (AC), 60 (BAT)

      MAX_LOST_WORK_SECS_ON_AC = 15;
      MAX_LOST_WORK_SECS_ON_BAT = 60;

      # Select a CPU scaling driver operation mode.
      # Intel CPU with intel_pstate driver:
      #   active, passive.
      # AMD Zen 2 or newer CPU with amd-pstate_driver as of kernel 6.3/6.4(*):
      #   active, passive, guided(*).
      # Default: <none>
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";

      # Select a CPU frequency scaling governor.
      # Intel CPU with intel_pstate driver or
      # AMD CPU with amd-pstate driver in active mode ('amd-pstate-epp'):
      #   performance, powersave(*).
      # Intel CPU with intel_pstate driver in passive mode ('intel_cpufreq') or
      # AMD CPU with amd-pstate driver in passive or guided mode ('amd-pstate') or
      # Intel, AMD and other CPU brands with acpi-cpufreq driver:
      #   conservative, ondemand(*), userspace, powersave, performance, schedutil(*).
      # Use tlp-stat -p to show the active driver and available governors.
      # Important:
      #   Governors marked (*) above are power efficient for *almost all* workloads
      #   and therefore kernel and most distributions have chosen them as defaults.
      #   You should have done your research about advantages/disadvantages *before*
      #   changing the governor.
      # Default: <none>

      # CPU_SCALING_GOVERNOR_ON_AC = "balance_power";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Set the min/max frequency available for the scaling governor.
      # Possible values depend on your CPU. For available frequencies see
      # the output of tlp-stat -p.
      # Notes:
      # - Min/max frequencies must always be specified for both AC *and* BAT
      # - Not recommended for use with the intel_pstate driver, use
      #   CPU_MIN/MAX_PERF_ON_AC/BAT below instead
      # Default: <none>

      CPU_SCALING_MIN_FREQ_ON_AC = 400000;
      CPU_SCALING_MAX_FREQ_ON_AC = 5132000;
      CPU_SCALING_MIN_FREQ_ON_BAT = 400000;
      CPU_SCALING_MAX_FREQ_ON_BAT = 1200000;

      # Set CPU energy/performance policies EPP and EPB:
      #   performance, balance_performance, default, balance_power, power.
      # Values are given in order of increasing power saving.
      # Requires:
      # * Intel CPU
      #   EPP: Intel Core i 6th gen. or newer CPU with intel_pstate driver
      #   EPB: Intel Core i 2nd gen. or newer CPU with intel_pstate driver
      #     as of kernel 5.2; alternatively module msr and
      #     x86_energy_perf_policy from linux-tools
      #   EPP and EPB are mutually exclusive: when EPP is available, Intel CPUs
      #   will not honor EPB. Only the matching feature will be applied by TLP.
      # * AMD Zen 2 or newer CPU
      #   EPP: amd-pstate driver in active mode ('amd-pstate-epp') as of kernel 6.3
      # Default: balance_performance (AC), balance_power (BAT)

      # CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Set Intel CPU P-state performance: 0..100 (%).
      # Limit the max/min P-state to control the power dissipation of the CPU.
      # Values are stated as a percentage of the available performance.
      # Requires Intel Core i 2nd gen. or newer CPU with intel_pstate driver.
      # Default: <none>

      # CPU_MIN_PERF_ON_AC = 0;
      # CPU_MAX_PERF_ON_AC = 100;
      # CPU_MIN_PERF_ON_BAT = 0;
      # CPU_MAX_PERF_ON_BAT = 30;

      # Set the CPU "turbo boost" (Intel) or "turbo core" (AMD) feature:
      #   0=disable, 1=allow.
      # Allows to raise the maximum frequency/P-state of some cores if the
      # CPU chip is not fully utilized and below it's intended thermal budget.
      # Note: a value of 1 does *not* activate boosting, it just allows it.
      # Default: <none>

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Set Intel/AMD CPU dynamic boost feature:
      #   0=disable, 1=enable.
      # Improve performance by increasing minimum P-state limit dynamically
      # whenever a task previously waiting on I/O is selected to run.
      # Requires:
      # * Intel Core i  6th gen. or newer CPU: intel_pstate driver in active mode
      # * AMD Zen 2 or newer CPU: amd-pstate driver in active mode ('amd-pstate-epp')
      #   provided by a yet unreleased kernel 6.x
      # Default: <none>

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Kernel NMI Watchdog:
      #   0=disable (default, saves power), 1=enable (for kernel debugging only).
      # Default: 0

      NMI_WATCHDOG = 0;

      # Select platform profile:
      #   performance, balanced, low-power.
      # Controls system operating characteristics around power/performance levels,
      # thermal and fan speed. Values are given in order of increasing power saving.
      # Note: check the output of tlp-stat -p to determine availability on your
      # hardware and additional profiles such as: balanced-performance, quiet, cool.
      # Default: <none>

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # System suspend mode:
      #   s2idle: Idle standby - a pure software, light-weight, system sleep state,
      #   deep: Suspend to RAM - the whole system is put into a low-power state,
      #     except for memory, usually resulting in higher savings than s2idle.
      # CAUTION: changing suspend mode may lead to system instability and even
      # data loss. As for the availability of different modes on your system,
      # check the output of tlp-stat -s. If unsure, stick with the system default
      # by not enabling this.
      # Default: <none>

      MEM_SLEEP_ON_AC = "s2idle";
      MEM_SLEEP_ON_BAT = "s2idle";

      # Define disk devices on which the following DISK/AHCI_RUNTIME parameters act.
      # Separate multiple devices with spaces.
      # Devices can be specified by disk ID also (lookup with: tlp diskid).
      # Default: "nvme0n1 sda"

      DISK_DEVICES = "nvme0n1 sda";

      # Disk advanced power management level: 1..254, 255 (max saving, min, off).
      # Levels 1..127 may spin down the disk; 255 allowable on most drives.
      # Separate values for multiple disks with spaces. Use the special value 'keep'
      # to keep the hardware default for the particular disk.
      # Default: 254 (AC), 128 (BAT)

      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "128 128";

      # Exclude disk classes from advanced power management (APM):
      #   sata, ata, usb, ieee1394.
      # Separate multiple classes with spaces.
      # CAUTION: USB and IEEE1394 disks may fail to mount or data may get corrupted
      # with APM enabled. Be careful and make sure you have backups of all affected
      # media before removing 'usb' or 'ieee1394' from the denylist!
      # Default: "usb ieee1394"

      #DISK_APM_CLASS_DENYLIST = "usb ieee1394";

      # Hard disk spin down timeout:
      #   0:        spin down disabled
      #   1..240:   timeouts from 5s to 20min (in units of 5s)
      #   241..251: timeouts from 30min to 5.5 hours (in units of 30min)
      # See 'man hdparm' for details.
      # Separate values for multiple disks with spaces. Use the special value 'keep'
      # to keep the hardware default for the particular disk.
      # Default: <none>

      #DISK_SPINDOWN_TIMEOUT_ON_AC = "0 0";
      #DISK_SPINDOWN_TIMEOUT_ON_BAT = "0 0";

      # Select I/O scheduler for the disk devices.
      # Multi queue (blk-mq) schedulers:
      #   mq-deadline(*), none, kyber, bfq
      # Single queue schedulers:
      #   deadline(*), cfq, bfq, noop
      # (*) recommended.
      # Separate values for multiple disks with spaces. Use the special value 'keep'
      # to keep the kernel default scheduler for the particular disk.
      # Notes:
      # - Multi queue (blk-mq) may need kernel boot option 'scsi_mod.use_blk_mq=1'
      #   and 'modprobe mq-deadline-iosched|kyber|bfq' on kernels < 5.0
      # - Single queue schedulers are legacy now and were removed together with
      #   the old block layer in kernel 5.0
      # Default: keep

      #DISK_IOSCHED = "mq-deadline mq-deadline";

      # AHCI link power management (ALPM) for SATA disks:
      #   min_power, med_power_with_dipm(*), medium_power, max_performance.
      # (*) recommended.
      # Multiple values separated with spaces are tried sequentially until success.
      # Default: med_power_with_dipm (AC & BAT)

      #SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      #SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      SATA_LINKPWR_ON_AC = "med_power_with_dipm max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm max_performance";

      # Exclude SATA links from AHCI link power management (ALPM).
      # SATA links are specified by their host. Refer to the output of
      # tlp-stat -d to determine the host; the format is "hostX".
      # Separate multiple hosts with spaces.
      # Default: <none>

      #SATA_LINKPWR_DENYLIST = "host1";

      # Runtime Power Management for NVMe, SATA, ATA and USB disks
      # as well as SATA ports:
      #   on=disable, auto=enable.
      # Note: SATA controllers are PCIe bus devices and handled by RUNTIME_PM further
      # down.

      # Default: on (AC), auto (BAT)

      #AHCI_RUNTIME_PM_ON_AC = "on";
      #AHCI_RUNTIME_PM_ON_BAT = "auto";

      # Seconds of inactivity before disk is suspended.
      # Note: effective only when AHCI_RUNTIME_PM_ON_AC/BAT is activated.
      # Default: 15

      AHCI_RUNTIME_PM_TIMEOUT = 15;

      # Power off optical drive in UltraBay/MediaBay: 0=disable, 1=enable.
      # Drive can be powered on again by releasing (and reinserting) the eject lever
      # or by pressing the disc eject button on newer models.
      # Note: an UltraBay/MediaBay hard disk is never powered off.
      # Default: 0

      #BAY_POWEROFF_ON_AC = 0;
      #BAY_POWEROFF_ON_BAT = 0;

      # Optical drive device to power off
      # Default: sr0

      #BAY_DEVICE = "sr0";

      # Set the min/max/turbo frequency for the Intel GPU.
      # Possible values depend on your hardware. For available frequencies see
      # the output of tlp-stat -g.
      # Default: <none>

      #INTEL_GPU_MIN_FREQ_ON_AC = 0;
      #INTEL_GPU_MIN_FREQ_ON_BAT = 0;
      #INTEL_GPU_MAX_FREQ_ON_AC = 0;
      #INTEL_GPU_MAX_FREQ_ON_BAT = 0;
      #INTEL_GPU_BOOST_FREQ_ON_AC = 0;
      #INTEL_GPU_BOOST_FREQ_ON_BAT = 0;

      # AMD GPU power management.
      # Performance level (DPM): auto, low, high; auto is recommended.
      # Note: requires amdgpu or radeon driver.
      # Default: auto

      RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";

      # Dynamic power management method (DPM): balanced, battery, performance.
      # Note: radeon driver only.
      # Default: <none>

      RADEON_DPM_STATE_ON_AC = "performance";
      RADEON_DPM_STATE_ON_BAT = "battery";

      # Graphics clock speed (profile method): low, mid, high, auto, default;
      # auto = mid on BAT, high on AC.
      # Note: radeon driver on legacy ATI hardware only (where DPM is not available).
      # Default: default

      RADEON_POWER_PROFILE_ON_AC = "default";
      RADEON_POWER_PROFILE_ON_BAT = "low";

      # Wi-Fi power saving mode: on=enable, off=disable.
      # Default: off (AC), on (BAT)

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Disable Wake-on-LAN: Y/N.
      # Default: Y

      WOL_DISABLE = "Y";

      # Enable audio power saving for Intel HDA, AC97 devices (timeout in secs).
      # A value of 0 disables, >= 1 enables power saving.
      # Note: 1 is recommended for Linux desktop environments with PulseAudio,
      # systems without PulseAudio may require 10.
      # Default: 1

      #SOUND_POWER_SAVE_ON_AC = 1;
      #SOUND_POWER_SAVE_ON_BAT = 1;

      # Disable controller too (HDA only): Y/N.
      # Note: effective only when SOUND_POWER_SAVE_ON_AC/BAT is activated.
      # Default: Y

      #SOUND_POWER_SAVE_CONTROLLER = "Y";

      # PCIe Active State Power Management (ASPM):
      #   default(*), performance, powersave, powersupersave.
      # (*) keeps BIOS ASPM defaults (recommended)
      # Default: <none>

      #PCIE_ASPM_ON_AC = "default";
      #PCIE_ASPM_ON_BAT = "default";
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersave";

      # Runtime Power Management for PCIe bus devices: on=disable, auto=enable.
      # Default: on (AC), auto (BAT)

      #RUNTIME_PM_ON_AC = "on";
      #RUNTIME_PM_ON_BAT = "auto";

      # Exclude listed PCIe device adresses from Runtime PM.
      # Note: this preserves the kernel driver default, to force a certain state
      # use RUNTIME_PM_ENABLE/DISABLE instead.
      # Separate multiple addresses with spaces.
      # Use lspci to get the adresses (1st column).
      # Default: <none>

      #RUNTIME_PM_DENYLIST = "11:22.3 44:55.6";

      # Exclude PCIe devices assigned to the listed drivers from Runtime PM.
      # Note: this preserves the kernel driver default, to force a certain state
      # use RUNTIME_PM_ENABLE/DISABLE instead.
      # Separate multiple drivers with spaces.
      # Default: "mei_me nouveau radeon", use "" to disable completely.

      #RUNTIME_PM_DRIVER_DENYLIST = "mei_me nouveau radeon";

      # Permanently enable/disable Runtime PM for listed PCIe device addresses
      # (independent of the power source). This has priority over all preceding
      # Runtime PM settings. Separate multiple addresses with spaces.
      # Use lspci to get the adresses (1st column).
      # Default: <none>

      #RUNTIME_PM_ENABLE = "11:22.3";
      #RUNTIME_PM_DISABLE = "44:55.6";

      # Set to 0 to disable, 1 to enable USB autosuspend feature.
      # Default: 1

      USB_AUTOSUSPEND = "1";

      # Exclude listed devices from USB autosuspend (separate with spaces).
      # Use lsusb to get the ids.
      # Note: input devices (usbhid) and libsane-supported scanners are excluded
      # automatically.
      # Default: <none>

      #USB_DENYLIST = "1111:2222 3333:4444";

      # Exclude audio devices from USB autosuspend:
      #   0=do not exclude, 1=exclude.
      # Default: 1

      USB_EXCLUDE_AUDIO = 1;

      # Exclude bluetooth devices from USB autosuspend:
      #   0=do not exclude, 1=exclude.
      # Default: 0

      USB_EXCLUDE_BTUSB = 0;

      # Exclude phone devices from USB autosuspend:
      #   0=do not exclude, 1=exclude (enable charging).
      # Default: 0

      USB_EXCLUDE_PHONE = 0;

      # Exclude printers from USB autosuspend:
      #   0=do not exclude, 1=exclude.
      # Default: 1

      USB_EXCLUDE_PRINTER = 1;

      # Exclude WWAN devices from USB autosuspend:
      #   0=do not exclude, 1=exclude.
      # Default: 0

      USB_EXCLUDE_WWAN = 0;

      # Allow USB autosuspend for listed devices even if already denylisted or
      # excluded above (separate with spaces). Use lsusb to get the ids.
      # Default: 0

      #USB_ALLOWLIST = "1111:2222 3333:4444";

      # Set to 1 to disable autosuspend before shutdown, 0 to do nothing
      # Note: use as a workaround for USB devices that cause shutdown problems.
      # Default: 0

      #USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 0;

      # Restore radio device state (Bluetooth, WiFi, WWAN) from previous shutdown
      # on system startup: 0=disable, 1=enable.
      # Note: the parameters DEVICES_TO_DISABLE/ENABLE_ON_STARTUP/SHUTDOWN below
      # are ignored when this is enabled.
      # Default: 0

      #RESTORE_DEVICE_STATE_ON_STARTUP = 0;

      # Radio devices to disable on startup: bluetooth, nfc, wifi, wwan.
      # Separate multiple devices with spaces.
      # Default: <none>

      #DEVICES_TO_DISABLE_ON_STARTUP="bluetooth nfc wifi wwan"

      # Radio devices to enable on startup: bluetooth, nfc, wifi, wwan.
      # Separate multiple devices with spaces.
      # Default: <none>

      #DEVICES_TO_ENABLE_ON_STARTUP = "wifi";

      # Radio devices to disable on shutdown: bluetooth, nfc, wifi, wwan.
      # Note: use as a workaround for devices that are blocking shutdown.
      # Default: <none>

      #DEVICES_TO_DISABLE_ON_SHUTDOWN = "bluetooth nfc wifi wwan"];

      # Radio devices to enable on shutdown: bluetooth, nfc, wifi, wwan.
      # (to prevent other operating systems from missing radios).
      # Default: <none>

      #DEVICES_TO_ENABLE_ON_SHUTDOWN = "wwan";

      # Radio devices to enable on AC: bluetooth, nfc, wifi, wwan.
      # Default: <none>

      #DEVICES_TO_ENABLE_ON_AC = "bluetooth nfc wifi wwan";

      # Radio devices to disable on battery: bluetooth, nfc, wifi, wwan.
      # Default: <none>

      #DEVICES_TO_DISABLE_ON_BAT = "bluetooth nfc wifi wwan";

      # Radio devices to disable on battery when not in use (not connected):
      #   bluetooth, nfc, wifi, wwan.
      # Default: <none>

      #DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth nfc wifi wwan";

      # Battery Care -- Charge thresholds
      # Charging starts when the charger is connected and the charge level
      # is below the start threshold. Charging stops when the charge level
      # is above the stop threshold.
      # Required hardware: Lenovo ThinkPads and select other laptop brands
      # are driven via specific plugins
      # - Active plugin and support status are shown by tlp-stat -b
      # - Vendor specific threshold levels are shown by tlp-stat -b, some
      #   laptops support only 1 (on)/ 0 (off) instead of a percentage level
      # - When your hardware supports a start *and* a stop threshold, you must
      #   specify both, otherwise TLP will refuse to apply the single threshold
      # - When your hardware supports only a stop threshold, set the start
      #   value to 0
      # - Older ThinkPads may require an external kernel module, refer to the
      #   output of tlp-stat -b
      # For further explanation and vendor specific details refer to
      # - https://linrunner.de/tlp/settings/battery.html
      # - https://linrunner.de/tlp/settings/bc-vendors.html

      # BAT0: Primary / Main / Internal battery
      # Note: also use for batteries BATC, BATT and CMB0
      # Default: <none>

      # Battery charge level below which charging will begin.
      START_CHARGE_THRESH_BAT0 = 75;
      # Battery charge level above which charging will stop.
      STOP_CHARGE_THRESH_BAT0 = 80;

      # ## High charge
      # START_CHARGE_THRESH_BAT0 = 98;
      # STOP_CHARGE_THRESH_BAT0 = 99;

      # BAT1: Secondary / Ultrabay / Slice / Replaceable battery
      # Note: primary on some laptops
      # Default: <none>

      # Battery charge level below which charging will begin.
      #START_CHARGE_THRESH_BAT1 = 75;
      # Battery charge level above which charging will stop.
      #STOP_CHARGE_THRESH_BAT1 = 80;

      # Restore charge thresholds when AC is unplugged: 0=disable, 1=enable.
      # Default: 0

      #RESTORE_THRESHOLDS_ON_BAT = 1;

      # Control battery care drivers: 0=disable, 1=enable.
      # Default: 1 (all)

      #NATACPI_ENABLE = 1;
      #TPACPI_ENABLE = 1;
      #TPSMAPI_ENABLE = 1;

      # ------------------------------------------------------------------------------
      # tlp-rdw - Parameters for the radio device wizard

      # Possible devices: bluetooth, wifi, wwan.
      # Separate multiple radio devices with spaces.
      # Default: <none> (for all parameters below)

      # Radio devices to disable on connect.

      #DEVICES_TO_DISABLE_ON_LAN_CONNECT = "wifi wwan";
      #DEVICES_TO_DISABLE_ON_WIFI_CONNECT = "wwan";
      #DEVICES_TO_DISABLE_ON_WWAN_CONNECT = "wifi";

      # Radio devices to enable on disconnect.

      #DEVICES_TO_ENABLE_ON_LAN_DISCONNECT = "wifi wwan";
      #DEVICES_TO_ENABLE_ON_WIFI_DISCONNECT = "";
      #DEVICES_TO_ENABLE_ON_WWAN_DISCONNECT = "";

      # Radio devices to enable/disable when docked.

      #DEVICES_TO_ENABLE_ON_DOCK = "";
      #DEVICES_TO_DISABLE_ON_DOCK = "";

      # Radio devices to enable/disable when undocked.

      #DEVICES_TO_ENABLE_ON_UNDOCK = "wifi";
      #DEVICES_TO_DISABLE_ON_UNDOCK = "";
    };
  };
}

