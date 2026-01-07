## See: https://nixos.wiki/wiki/AMD_GPU

{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.hostParams.gpu.amd.enable {
    ## Use AMD GPU from the start
    boot.initrd.kernelModules = [ "amdgpu" ];

    hardware = {
      graphics = {
        # Needed for Steam
        enable32Bit = true;
      };
    };

    environment.systemPackages = [
      # Used to test that rocmPackages above working properly
      pkgs.clinfo
      pkgs.lact
    ];

    nixpkgs.config.rocmSupport = true;

    services.lact.enable = true;

    # systemd.services.lact = {
    #   description = "AMDGPU Control Daemon";
    #   after = ["multi-user.target"];
    #   wantedBy = ["multi-user.target"];
    #   serviceConfig = {
    #     ExecStart = "${pkgs.lact}/bin/lact daemon";
    #   };
    #   enable = true;
    # };

    boot.blacklistedKernelModules = [ "radeon" "fglrx" ];

    # dc=0 causes hanges at module load
    # Commented out experimental options that may cause DMUB interrupt storms under load:
    # - vm_fragment_size=9: Non-standard VM fragmentation
    # - aspm=0: Disables PCIe ASPM (conflicts with TLP)
    # - ppfeaturemask=0xffffffff: Enables ALL power features (risky)
    boot.extraModprobeConfig = ''
      options amdgpu si_support=1 cik_support=1 audio=0
    '';
  };
}
