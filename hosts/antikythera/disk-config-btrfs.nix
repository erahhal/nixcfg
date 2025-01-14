{ ... }:
{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
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
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                extraOpenArgs = [
                  "--allow-discards"
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];
                settings = {
                  crypttabExtraOpts = ["fido2-device=auto" "token-timeout=10"];
                };

                # disable settings.keyFile if you want to use interactive password entry
                # passwordFile = "/tmp/secret.key"; # Interactive
                # settings = {
                #   allowDiscards = true;
                #   keyFile = "/tmp/secret.key";
                # };
                # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];

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
                    # Subvolume for the swapfile
                    "/swap" = {
                      mountpoint = "/swap";
                      swap = {
                        swapfile.size = "64G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
