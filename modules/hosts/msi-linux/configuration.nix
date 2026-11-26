{ config, lib, pkgs, ... }:
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
      chromium-based-apps.braveSyncUrl = "https://brave-sync.homefree.host/v2";
    };
    networking = {
      mullvad.enable = true;
      kdeconnect.enable = true;
      connection-sharing.enable = true;
    };
    hardware = {
      gfx-nvidia.enable = true;
      gfx-intel.enable = true;
      laptop.enable = true;
      udev-rules.enable = true;
      openrgb = {
        enable = true;
        motherboard = "intel";
        profile = ./Aquamarine.orp;
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
      nfs-mounts.enable = config.hostParams.services.nfs-mounts.enable;
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
    timeout = 75;

    systemd-boot = {
      enable = true;
      configurationLimit = 4;
      consoleMode = "max";

      windows = {
        "windows" =
          let
            # To determine the name of the windows boot drive, boot into edk2 first, then run
            # `map -c` and find the handle whose device path is the Windows ESP's
            # HD(1,GPT,5CB2EA4C-...). Use that consistent HDxy name, not an FSn alias: FS numbers
            # shift when partitions are added (the Games partition turned FS1 into FS2).
            boot-drive = "HD1b";
          in
          {
            title = "Windows";
            efiDeviceHandle = boot-drive;
            sortKey = "y_windows";
          };
      };

      edk2-uefi-shell.enable = true;
      edk2-uefi-shell.sortKey = "z_edk2";
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

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  # -------
  # OpenRGB
  # -------

  boot.kernelModules = [ "i2c-dev" "snd-hda-intel" "kvm-intel" ];

  hardware.i2c.enable = true;

  ## Experimental

  nix.settings.extra-platforms = [ "i686-linux" ];
  nix.settings.sandbox = true;
  boot.binfmt.emulatedSystems = [ "i686-linux" ];
  # boot.kernel.sysctl."abi.vsyscall32" = 1;

  systemd.services.fix-console-fb = {
    description = "Set frambuffer resolution";
    wantedBy = [ "multi-user.target" ];
    before = [ "getty@tty1.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.fbset}/bin/fbset -g 3840 2160 3840 2160 32";
    };
  };

  # Watchdog for known-latent btrfs extent-tree damage on /: fails the unit if any device stat counter becomes non-zero.
  systemd.services.btrfs-device-stats-check = {
    description = "Check btrfs device error counters on /";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrfs-progs}/bin/btrfs device stats -c /";
    };
  };
  systemd.timers.btrfs-device-stats-check = {
    description = "Weekly btrfs device stats check on /";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  # --------------------------------------------------------------------------------------
  # Shared Steam library: NTFS partition "Games" (D: in Windows)
  # --------------------------------------------------------------------------------------

  # In-kernel ntfs3 driver. No "force" option on purpose: if Windows leaves the volume dirty
  # (crash / forced power-off) it mounts read-only instead of risking damage.
  # Proton prefixes (steamapps/compatdata) stay on btrfs via a symlink - see ~/STEAM-MIGRATION.md.
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-partlabel/Games";
    fsType = "ntfs3";
    options = [ "uid=1000" "gid=100" "umask=022" "windows_names" "nofail" "x-systemd.device-timeout=10s" ];
  };

  # Flatpak Steam only sees paths granted in its overrides; merged with the list in modules/programs/flatpak.
  # Grant library drives one by one: the Flathub launcher refuses to start with "host", "home" or ~ access.
  services.flatpak.overrides."com.valvesoftware.Steam".Context.filesystems = [ "/mnt/games" ];
}

