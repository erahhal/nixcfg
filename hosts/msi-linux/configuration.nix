{ config, inputs, lib, pkgs, userParams, ... }:
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  imports =
    [
      ./disk-config-btrfs.nix
      ../../profiles/common.nix
      ../../profiles/desktop.nix
      # ../../profiles/jovian.nix
      ../../profiles/mullvad.nix
      ../../profiles/openrgb.nix
      ../../profiles/pipewire.nix
      # ../../profiles/steambox.nix
      # ../../profiles/steam.nix
      ./steam-fix.nix
      ../../profiles/udev.nix
      ../../profiles/keyboard-debounce.nix
      ## @TODO: rename workstation-hardware.nix
      ../../profiles/laptop-hardware.nix
      ../../overlays/chromium-based-apps.nix

      ../../home/user.nix
      ../../home/desktop.nix

      # user specific
      ./user.nix

      # display
      ./sway.nix
      ./kanshi.nix

      ../../profiles/nfs-mounts.nix
      # ../../profiles/smb-mounts.nix
      ../../profiles/kdeconnect.nix
    ];

  # Disable gnome-keyring since we use autologin and don't need password storage
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # Needed to setup passwords
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNvmGn1/uFnfgnv5qsec0GC04LeVB1Qy/G7WivvvUZVBBDzp8goe1DsE8M8iqnBSin56gQZDWsd50co2MbFAWuqH2HxY7OGay7P/V2q+SziTYFva85WGl84qWvYMmdB+alAFBT3L4eH5cegC5NhNp+OGsQuq32RdojgXXQt6vyZnaOypuz90k3rqV6Rt+iBTLz6VziasCLcYydwOvi9f1q6YQwGPLKaupDrV6gxvoX9bXLdopqwnXPSE/Eqczxgwc3PefvAJPSd6TOqIXvbtpv/B3Evt5SPe2gq+qASc5K0tzgra8KAe813kkpq4FuKJzHbT+EmO70wiJjru7zMEhd erahhal@nfml-erahhalQFL"
  ];
  users.users.${userParams.username}.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNvmGn1/uFnfgnv5qsec0GC04LeVB1Qy/G7WivvvUZVBBDzp8goe1DsE8M8iqnBSin56gQZDWsd50co2MbFAWuqH2HxY7OGay7P/V2q+SziTYFva85WGl84qWvYMmdB+alAFBT3L4eH5cegC5NhNp+OGsQuq32RdojgXXQt6vyZnaOypuz90k3rqV6Rt+iBTLz6VziasCLcYydwOvi9f1q6YQwGPLKaupDrV6gxvoX9bXLdopqwnXPSE/Eqczxgwc3PefvAJPSd6TOqIXvbtpv/B3Evt5SPe2gq+qASc5K0tzgra8KAe813kkpq4FuKJzHbT+EmO70wiJjru7zMEhd erahhal@nfml-erahhalQFL"
  ];

  time.timeZone = config.hostParams.system.timeZone;

  # --------------------------------------------------------------------------------------
  # Nix
  # --------------------------------------------------------------------------------------
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" "nixos-config=/home/${userParams.username}/Code/nixcfg" ];

  networking = {
    hostName = config.hostParams.system.hostName;
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
            # `map -c` to get drive aliases, and try out running `FS1:`, then `ls EFI` to check
            # which alias corresponds to which EFI partition.
            boot-drive = "FS1";
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

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  services.syslogd.enable = true;

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
}

