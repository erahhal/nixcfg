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
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              size = "64G";
              type = "8200";
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100; # prefer to encrypt as long as we have space for it
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };

    # zpool = {
    #   zroot = {
    #     type = "zpool";
    #     rootFsOptions = {
    #       compression = "zstd";
    #       "com.sun:auto-snapshot" = "false";
    #     };
    #     mountpoint = "/";
    #     postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank";
    #
    #     datasets = {
    #       zfs_fs = {
    #         type = "zfs_fs";
    #         mountpoint = "/zfs_fs";
    #         options."com.sun:auto-snapshot" = "true";
    #       };
    #       zfs_unmounted_fs = {
    #         type = "zfs_fs";
    #         options.mountpoint = "none";
    #       };
    #       zfs_legacy_fs = {
    #         type = "zfs_fs";
    #         options.mountpoint = "legacy";
    #         mountpoint = "/zfs_legacy_fs";
    #       };
    #       zfs_testvolume = {
    #         type = "zfs_volume";
    #         size = "10M";
    #         content = {
    #           type = "filesystem";
    #           format = "ext4";
    #           mountpoint = "/ext4onzfs";
    #         };
    #       };
    #       encrypted = {
    #         type = "zfs_fs";
    #         options = {
    #           mountpoint = "none";
    #           encryption = "aes-256-gcm";
    #           keyformat = "passphrase";
    #           keylocation = "file:///tmp/secret.key";
    #         };
    #         # use this to read the key during boot
    #         # postCreateHook = ''
    #         #   zfs set keylocation="prompt" "zroot/$name";
    #         # '';
    #       };
    #       "encrypted/test" = {
    #         type = "zfs_fs";
    #         mountpoint = "/zfs_crypted";
    #       };
    #     };
    #   };
    # };

    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          # Allows setting additional access rights
          acltype = "posixacl";
          # Stores extended attributes in the inode, rathr than hidden subdirs, increasing performance
          xattr = "sa";
          canmount = "off";
          checksum = "edonr";
          # Faster but worse compression than zstd
          # @TODO: Is this true though? The SSD is the bottleneck, not the CPU, so more compressed data may be faster
          compression = "lz4";
          dnodesize = "auto";
          # encryption does not appear to work in vm test; only use on real system
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "prompt";
          normalization = "formD";
          relatime = "on";
        };
        mountpoint = null;
        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          local = {
            type = "zfs_fs";
            options.canmount = "off";
          };

          safe = {
            type = "zfs_fs";
            options.canmount = "off";
          };

          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "/";
            postCreateHook = ''
              zfs snapshot zroot/local/root@empty
            '';
          };

          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "/nix";
          };

          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "/home";
          };

          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options.mountpoint = "/persist";
          };
        };
      };
    };

    # zpool = {
    #   zroot = {
    #     type = "zpool";
    #     rootFsOptions = {
    #       acltype = "posixacl";
    #       canmount = "off";
    #       checksum = "edonr";
    #       compression = "lz4";
    #       dnodesize = "auto";
    #       # encryption does not appear to work in vm test; only use on real system
    #       encryption = "aes-256-gcm";
    #       keyformat = "passphrase";
    #       keylocation = "prompt";
    #       normalization = "formD";
    #       relatime = "on";
    #       xattr = "sa";
    #     };
    #     mountpoint = null;
    #     options = {
    #       ashift = "12";
    #       autotrim = "on";
    #     };

    #     datasets = {
    #       local = {
    #         type = "zfs_fs";
    #         options.canmount = "off";
    #       };

    #       safe = {
    #         type = "zfs_fs";
    #         options.canmount = "off";
    #       };

    #       "local/root" = {
    #         type = "zfs_fs";
    #         mountpoint = "/";
    #         options.mountpoint = "/";
    #         postCreateHook = ''
    #           zfs snapshot zroot/local/root@empty
    #         '';
    #       };

    #       "local/nix" = {
    #         type = "zfs_fs";
    #         mountpoint = "/nix";
    #         options.mountpoint = "/nix";
    #       };

    #       "safe/home" = {
    #         type = "zfs_fs";
    #         mountpoint = "/home";
    #         options.mountpoint = "/home";
    #       };

    #       "safe/persist" = {
    #         type = "zfs_fs";
    #         mountpoint = "/persist";
    #         options.mountpoint = "/persist";
    #       };
    #     };
    #   };
    # };
  };
}
