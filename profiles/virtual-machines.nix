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

{ lib, pkgs, hostParams, userParams, ...}:
let
  run-homefree = pkgs.writeScriptBin "run-homefree" ''
    #!${pkgs.stdenv.shell}

    export ENV_EFI_CODE_SECURE=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd
    export ENV_EFI_VARS_SECURE=${pkgs.OVMF.fd}/FV/OVMF_VARS.fd

    quickemu --vm homefree.conf --display spice
  '';
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
    unstable.quickemu
    virt-manager
    virtiofsd         # needed for file system sharing

    run-homefree
    run-windows
  ];

  #-------------------------------------------
  ## libvirtd
  #-------------------------------------------

  # @TODO: How to start default network at boot?
  # sudo virsh net-start --network default

  # allow nested virtualization inside guests
  boot.extraModprobeConfig = "options kvm_intel nested=1";


  virtualisation.libvirtd = {
    enable = true;

    allowedBridges = [
      "nm-bridge"
      "virbr0"
    ];

    qemu = {
      runAsRoot = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
      swtpm.enable = true;
    };
  };

  #-------------------------------------------
  ## QEMU/KVM
  #-------------------------------------------

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  services.qemuGuest.enable = true;

  # Intel GVT-g - GPU virtualisation
  virtualisation.kvmgt = {
    enable = true;
  };

  #-------------------------------------------
  ## virt-manager settings
  #
  # https://nixos.wiki/wiki/Virt-manager
  #-------------------------------------------

  ## @TODO: Enable with NixOS 23.11
  # programs.virt-manager.enable = true;

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

  virtualisation.virtualbox = if hostParams.virtualboxEnabled == true then {
    host = {
      enable = true;
      enableExtensionPack = true;
    };
    # guest = {
    #   enable = true;
    #   x11 = true;
    # };
  } else {};

  #-------------------------------------------
  ## lxd
  #-------------------------------------------

  virtualisation.lxd.enable = true;
}
