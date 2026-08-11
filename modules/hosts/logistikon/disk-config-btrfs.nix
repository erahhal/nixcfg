{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-WD_BLACK_SN8100_4000GB_25374X801979";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              # label = "boot";
              # name = "ESP";
              start = "1M";
              end = "1G";
              # size = "1G";
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
                  # NOTE: disko only creates this file if it does not already
                  # exist, so changing the size here does NOT resize a live
                  # swapfile — it only applies to a fresh format/reinstall.
                  # Resize an existing one by hand:
                  #   systemctl stop swap-swapfile.swap
                  #   rm /swap/swapfile
                  #   btrfs filesystem mkswapfile --size 32g /swap/swapfile
                  #   systemctl start swap-swapfile.swap
                  "/swap" = {
                    mountpoint = "/swap";
                    swap = {
                      swapfile.size = "32G";
                    };
                  };
                };

                mountpoint = "/partition-root";
              };
            };
          };
        };
      };

      ## The 2TB that used to be `main`, kept as working space after the
      ## 2026-08-10 migration onto the WD. Named for what it is FOR, not for
      ## what is in the slot — `disk-main-*` survived that migration intact
      ## precisely because it was never called `disk-samsung-*`.
      ##
      ## Deliberately a SEPARATE filesystem rather than `btrfs device add` on
      ## to `main`. Pooling would give one 5.5TB fs, and would break swap:
      ## btrfs(5) requires a swapfile's filesystem be single-device, and this
      ## box swaps to /swap/swapfile. It would also mean losing either drive
      ## loses everything, since single-profile data would span both.
      ##
      ## `nofail` because scratch is by definition reproducible — a drive
      ## that is absent, unformatted or pulled must never hold up a boot.
      ##
      ## NEVER reach for `disko --mode format` to (re)make this one. It is
      ## all-or-nothing across `disko.devices` and would take `main` — the
      ## running system — with it. This disk was partitioned and mkfs'd by
      ## hand to match what is declared here; do the same next time.
      scratch = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0L306845Z";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                mountpoint = "/mnt/scratch";
                mountOptions = [ "compress=zstd" "discard=async" "noatime" "nofail" ];
              };
            };
          };
        };
      };
    };
  };
}
