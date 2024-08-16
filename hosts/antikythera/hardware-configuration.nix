{ config, lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [  ];
  boot.kernelModules = [ "kvm-intel" "thinkpad-acpi" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "rpool/root";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "rpool/nix";
      fsType = "zfs";
    };

  fileSystems."/var" =
    { device = "rpool/var";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "rpool/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/E19E-CD7B";
      fsType = "vfat";
    };

  # swapDevices = [
  #   {
  #     device = "/dev/nvme0n1p2";
  #     randomEncryption = true;
  #   }
  # ];

  ## Disable swap
  swapDevices = lib.mkForce [ ];

  ## Enable zramswap (must disable swap above)
  ## Supposedly helps with out of memory errors during compilation of big projects
  zramSwap = {
    enable = true;
    writebackDevice = "/dev/nvme0n1p2";
  };

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

  # Needed by ZFS
  networking.hostId = "2118a134";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
