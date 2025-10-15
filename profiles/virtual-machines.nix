#
# To install windows:
#
#   quickget windows 11
#
# To run:
#
#   quickemu --vm windows-11.conf
#
# For virt-manager, you will get an error on first run:
#
#   Could not detect a default hypervisor.
#
# To resolve:
#
#   File (in the menu bar) -> Add connection
#
#   HyperVisor = QEMU/KVM
#   Autoconnect = checkmark
#
#   Connect

{ config, lib, pkgs, userParams, ...}:
let
  run-windows = pkgs.writeScriptBin "run-windows" ''
    #!${pkgs.stdenv.shell}

    export ENV_EFI_CODE_SECURE=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd
    export ENV_EFI_VARS_SECURE=${pkgs.OVMF.fd}/FV/OVMF_VARS.fd

    quickemu --vm windows-11.conf --display spice
  '';
in
{
  #-------------------------------------------
  ## Imports
  #-------------------------------------------

  imports = [
    # ./kvm-def.nix
  ];

  #-------------------------------------------
  ## Packages
  #-------------------------------------------

  environment.systemPackages = with pkgs; [
    quickemu
    virt-manager
    virt-viewer
    virtiofsd         # needed for file system sharing

    run-windows
  ];

  #-------------------------------------------
  ## Allow cross compilation
  #-------------------------------------------

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  #-------------------------------------------
  ## libvirtd
  #-------------------------------------------

  # @TODO: How to start default network at boot?
  # sudo virsh net-start --network default

  # allow nested virtualization inside guests
  boot.extraModprobeConfig = "options kvm_intel nested=1";
  boot.kernelParams = [
    "intel_iommu=on"
  ];

  virtualisation.libvirtd = {
    enable = config.hostParams.virtualisation.libvirtd.enable;

    allowedBridges = [
      "nm-bridge"
      "virbr0"
      "hfbr0"
    ];

    qemu = {
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  # Start default network
  systemd.services = {
    virsh-start-default = {
      description = "Start default network at startup";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";
      serviceConfig.Restart = "on-failure";
      script =  ''
        VIRSH=${pkgs.libvirt}/bin/virsh
        GREP=${pkgs.gnugrep}/bin/grep
        AWK=${pkgs.gawk}/bin/awk
        state=$($VIRSH net-list | $GREP default | $AWK '{print $2}')
        if [ $state != 'active' ]; then
          $VIRSH net-start default
        fi
      '';
    };
  };

  # Start bridge for HomeFree
  ## See: https://www.spad.uk/posts/really-simple-network-bridging-with-qemu/
  systemd.services = {
    create-hfbr0 = {
      description = "Create second libvirt bridge - hfbr0";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";
      serviceConfig.Restart = "on-failure";
      script =  ''
        ETHTOOL=${pkgs.ethtool}/bin/ethtool
        IP=${pkgs.iproute2}/bin/ip
        GREP=${pkgs.gnugrep}/bin/grep
        if $ETHTOOL hfbr0 | $GREP -q "Link detected"; then
          echo "hfbr0 already up."
        else
          $IP link add hfbr0 type bridge
          # $IP addr add 192.168.123.1/24 dev hfbr0
          $IP link set hfbr0 up
        fi
      '';
    };
  };

  # See: https://www.reddit.com/r/NixOS/comments/knjxsb/adding_virtual_machines_to_physical_network/
  # networking = {
  #   bridges = {
  #     hfbrwan = {
  #       interfaces = [ "wlp0s20f3" ];
  #     };
  #   };
  #
  #   interfaces = {
  #     hfbrwan = {
  #       useDHCP = true;
  #     };
  #     hftap0 = {
  #       virtual = true;
  #       macAddress = "52:53:54:55:56:01";
  #       useDHCP = true;
  #     };
  #   };
  # };

  #-------------------------------------------
  ## QEMU/KVM
  #-------------------------------------------

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  services.qemuGuest.enable = true;

  # Intel GVT-g - GPU virtualisation
  virtualisation.kvmgt = {
    enable = true;
  };

  # Used by HomeFree
  # networking.bridges = {
  #   br0 = {
  #     interfaces = [ "wlp0s20f3" ];
  #   };
  # };

  # networking.interfaces = {
  #
  #   # br0.useDHCP = true;
  #   # wlp0s20f3.useDHCP = true;
  #
  #   tap-lan = {
  #     virtual = true;
  #     virtualType = "tap";
  #   };
  #
  #   tap-wan = {
  #     virtual = true;
  #     virtualType = "tap";
  #   };
  # };

  #-------------------------------------------
  ## virt-manager settings
  #
  # https://nixos.wiki/wiki/Virt-manager
  #-------------------------------------------

  # virt-manager requires dconf to remember settings
  ## @TODO: remove with 23.11, as it is automatically set by the setting above
  programs.dconf.enable = true;

  # declaratively add QEMU connection instead of manually through UI
  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };

    xdg.configFile."libvirt/qemu.conf".text = ''
      # Adapted from /var/lib/libvirt/qemu.conf
      # Note that AAVMF and OVMF are for Aarch64 and x86 respectively
      nvram = [ "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd", "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd" ]
    '';
  };

  # give user rights to do admin
  users.users.${userParams.username}.extraGroups = [ "libvirtd" ];

  users.extraGroups.vboxusers.members = [ userParams.username ];

  #-------------------------------------------
  ## Virtualbox
  #-------------------------------------------

  virtualisation.virtualbox = lib.mkIf config.hostParams.virtualisation.virtualbox.enable {
    host = {
      enable = true;
      enableExtensionPack = true;

      enableKvm = true;
      ## Must be set to false if enableKvm is true
      addNetworkInterface = false;
    };
    guest = {
      enable = true;
    };
  };

  #-------------------------------------------
  ## VMWare
  #-------------------------------------------

  # This thing sucks, requires manually downloading vmware first
  ## Message
  # > Unfortunately, we cannot download file VMware-Workstation-Full-17.6.3-24583834.x86_64.bundle automatically.
  # > Please go to https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true to download it yourself, and add it to the Nix store
  # > using either
  # >   nix-store --add-fixed sha256 VMware-Workstation-Full-17.6.3-24583834.x86_64.bundle
  # > or
  # >   nix-prefetch-url --type sha256 file:///path/to/VMware-Workstation-Full-17.6.3-24583834.x86_64.bundle
  virtualisation.vmware.host = lib.mkIf config.hostParams.virtualisation.vmware.enable {
    enable = true;
  };
}
