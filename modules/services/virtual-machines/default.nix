{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.services.virtual-machines;

  run-windows = pkgs.writeScriptBin "run-windows" ''
    #!${pkgs.stdenv.shell}

    export ENV_EFI_CODE_SECURE=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd
    export ENV_EFI_VARS_SECURE=${pkgs.OVMF.fd}/FV/OVMF_VARS.fd

    quickemu --vm windows-11.conf --display spice
  '';
in {
  options.nixcfg.services.virtual-machines = {
    enable = lib.mkEnableOption "QEMU/KVM virtual machine support";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      quickemu
      virt-manager
      virt-viewer
      virtiofsd
      run-windows
    ];

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

    systemd.services = {
      virsh-start-default = {
        description = "Start default network at startup";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig.Type = "oneshot";
        serviceConfig.Restart = "on-failure";
        script = ''
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

    boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

    services.qemuGuest.enable = true;

    virtualisation.kvmgt = {
      enable = true;
    };

    programs.dconf.enable = true;

    home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
        };
      };

      xdg.configFile."libvirt/qemu.conf".text = ''
        nvram = [ "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd", "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd" ]
      '';
    };

    users.users.${userParams.username}.extraGroups = [ "libvirtd" ];
    users.extraGroups.vboxusers.members = [ userParams.username ];

    virtualisation.virtualbox = lib.mkIf config.hostParams.virtualisation.virtualbox.enable {
      host = {
        enable = true;
        enableExtensionPack = true;
        enableKvm = true;
        addNetworkInterface = false;
      };
    };

    virtualisation.vmware.host = lib.mkIf config.hostParams.virtualisation.vmware.enable {
      enable = true;
    };
  };
}
