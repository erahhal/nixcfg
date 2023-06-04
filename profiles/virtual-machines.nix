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

{ pkgs, hostParams, userParams, ...}:
let
  run-windows = pkgs.writeScriptBin "run-windows" ''
    #!${pkgs.stdenv.shell}


    export ENV_EFI_CODE_SECURE=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd
    export ENV_EFI_VARS_SECURE=${pkgs.OVMF.fd}/FV/OVMF_VARS.fd

    quickemu --vm windows-11.conf --display spice
  '';
in
{
  users.users.${userParams.username}.extraGroups = [ "libvirtd" ];
  users.extraGroups.vboxusers.members = [ userParams.username ];

  services.qemuGuest.enable = true;
  virtualisation = {
    kvmgt.enable = true;

    libvirtd  = {
      allowedBridges = [
        "nm-bridge"
        "virbr0"
      ];

      enable = true;
      qemu = {
        runAsRoot = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull ];
        };
        # swtpm.enable = true;
      };
    };

    virtualbox = if hostParams.virtualboxEnabled == true then {
      host = {
        enable = true;
        enableExtensionPack = true;
      };
      # guest = {
      #   enable = true;
      #   x11 = true;
      # };
    } else {};
  };
  environment.systemPackages = with pkgs; [
    unstable.quickemu
    virt-manager

    run-windows
  ];
}
