{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_24521J802608";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              # label = "boot";
              # name = "ESP";
              start = "1M";
              end = "512M";
              # size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # mountOptions = [ "defaults" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "subvol=root" "compress=zstd" "discard=async" "noatime" ];
                  };
                  # Subvolume name is the same as the mountpoint
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "subvol=home"  "compress=zstd" "discard=async" "noatime" ];
                  };
                  # Parent is not mounted so the mountpoint must be set
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "subvol=nix" "compress=zstd" "discard=async" "noatime" ];
                  };
                  # Subvolume for the swapfile.
                  # 16G on a 64GB-RAM host: overflow only. This machine does
                  # not hibernate, so swap does not need to be >= RAM (and
                  # boot.resumeDevice / resume_offset are deliberately unset).
                  #
                  # NOTE: disko only creates this file if it does not already
                  # exist, so changing the size here does NOT resize a live
                  # swapfile — it only applies to a fresh format/reinstall.
                  # Resize an existing one by hand:
                  #   systemctl stop swap-swapfile.swap
                  #   rm /swap/swapfile
                  #   btrfs filesystem mkswapfile --size 16g /swap/swapfile
                  #   systemctl start swap-swapfile.swap
                  "/swap" = {
                    mountpoint = "/swap";
                    swap = {
                      swapfile.size = "16G";
                    };
                  };
                };

                mountpoint = "/partition-root";
              };
            };
          };
        };
      };
    };
  };
}
