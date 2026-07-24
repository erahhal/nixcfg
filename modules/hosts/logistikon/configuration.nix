{ config, pkgs, ... }:
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  nixcfg = {
    desktop = {
      enable = true;
      niri.enable = true;
      dms.enable = true;
      pipewire.enable = true;
      fonts.enable = true;
      chromium-based-apps.enable = true;
    };
    networking = {
      mullvad.enable = true;
      kdeconnect.enable = true;
      connection-sharing.enable = true;
    };
    hardware = {
      gfx-nvidia.enable = true;
      gfx-amd.enable = true;
      udev-rules.enable = true;
      openrgb = {
        enable = true;
        motherboard = "amd";
        profile = ./Red.orp;
      };
      keyboard-debounce.enable = true;
      spacenavd.enable = true;
    };
    programs = {
      android.enable = true;
      flatpak.enable = true;
      flox.enable = true;
      switchyard.enable = true;
    };
    services = {
      nfs-mounts.enable = true;
    };
  };

  ## AI model-serving stack (external flake: ~/Code/genai-server)
  services.genai-server.enable = true;
  ## genai group: write access to the shared model store
  ## (/var/lib/genai-models), LoRA store, and training jobs — no sudo needed
  ## for lora-train / lora-add / genai-fetch-media.
  users.users.${config.hostParams.user.username}.extraGroups = [ "genai" ];
  ## Serve on all interfaces (WiFi now, Ethernet later). NOTE: the WebUI and
  ## APIs are unauthenticated — the whole LAN gets full access.
  services.genai-server.openFirewallGlobally = true;
  ## Name that resolves for every LAN client (bare "logistikon" doesn't).
  services.genai-server.mediaPublicUrl = "http://logistikon.lan:8894";
  ## MagenticLite (:8895) rejects non-localhost Host headers unless listed
  ## (upstream DNS-rebinding defense; the launcher extends the allowlist).
  services.genai-server.magenticUi.allowedHosts = [ "logistikon.lan" ];
  ## LAN access in addition to the (not-yet-enabled) tailnet. NOTE: Open
  ## WebUI runs with auth disabled — every device on the LAN gets full
  ## access to the UI and APIs.
  services.genai-server.firewallInterfaces = [ "tailscale0" "wlan0" ];
  ## Civitai API token (shared agenix secret): lets image-server download
  ## the token-gated flux_nsfw checkpoint at startup. Without it those
  ## requests 503 ("checkpoint not downloaded").
  services.genai-server.civitaiTokenFile = config.age.secrets."civitai-token".path;

  ## GPU-inference box: the desktop stack enables power-profiles-daemon,
  ## which defaulted to "balanced" — community-measured ~15% llama.cpp
  ## throughput loss vs performance (found set to balanced 2026-07-20).
  ## ppd persists the profile in /var/lib, but pin it at boot so a fresh
  ## state dir or DE change can't silently regress inference speed.
  systemd.services.power-profile-performance = {
    description = "Pin power-profiles-daemon profile to performance";
    wantedBy = [ "multi-user.target" ];
    after = [ "power-profiles-daemon.service" ];
    requires = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
    };
  };

  imports =
    [
      ./disk-config-btrfs.nix
      ./steam-fix.nix

      # user specific
      ./user.nix

      # display
      ./kanshi.nix
      ../../desktop/niri/user-window-rules.nix
      ../../desktop/niri/user-overrides.nix
    ];

  networking = {
    networkmanager = {
      enable = true;
    };
  };

  # --------------------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------------------

  boot.loader = {
    timeout = 5;

    systemd-boot = {
      enable = true;
      configurationLimit = 4;
      consoleMode = "max";
    };

    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };

    # grub = {
    #   # despite what the configuration.nix manpage seems to indicate,
    #   # as of release 17.09, setting device to "nodev" will still call
    #   # `grub-install` if efiSupport is true
    #   # (the devices list is not used by the EFI grub install,
    #   # but must be set to some value in order to pass an assert in grub.nix)
    #   devices = [ "nodev" ];
    #   efiSupport = true;
    #   enable = true;
    #   # set $FS_UUID to the UUID of the EFI partition
    #   extraEntries = ''
    #     menuentry "Windows" {
    #       insmod part_gpt
    #       insmod fat
    #       insmod search_fs_uuid
    #       insmod chain
    #       search --fs-uuid --set=root $FS_UUID
    #       chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    #     }
    #   '';
    #   useOSProber = true;
    # };
  };

  ## Settings that supposedly increase gaming perf and prevent HDMI audio dropouts during gaming
  boot.kernelParams = [
    "preempt=full"    # Realitime latency
    "nohz_full=all"   # Reduce latency for realtime apps
    "threadirqs"      # forces most interrupt handlers to run in a threaded context, thus reducing input latency.
    # "video=3840x2160@60"
    # "video=efifb"
  ];

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  boot.kernelModules = [ "snd-hda-intel" "kvm-amd" ];

  ## Onboard Bluetooth and ASMedia ASM4242 USB4 (previously provided by the laptop module)
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.hardware.bolt.enable = true;

  ## Experimental

  nix.settings.extra-platforms = [ "i686-linux" ];
  nix.settings.sandbox = true;
  boot.binfmt.emulatedSystems = [ "i686-linux" ];
  # boot.kernel.sysctl."abi.vsyscall32" = 1;
}

