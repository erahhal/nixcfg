## See: https://nixos.wiki/wiki/AMD_GPU

{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.gfx-amd;
in
{
  key = "nixcfg/hardware/gfx-amd";

  options.nixcfg.hardware.gfx-amd.enable = lib.mkEnableOption "AMD GPU support";

  config = lib.mkIf cfg.enable {
    ## Use AMD GPU from the start
    boot.initrd.kernelModules = [ "amdgpu" ];

    hardware = {
      graphics = {
        # Without enable=true, /run/opengl-driver/lib gets mesa backends
        # (libEGL_mesa.so, libGLX_mesa.so) but no libglvnd dispatchers
        # (libGL.so.1, libEGL.so).  Firefox's glxtest then fails to dlopen
        # libGL.so.1, gfxInfo records FEATURE_FAILURE_BROKEN_DRIVER, and
        # DMA-BUF / VAAPI get blocklisted — forcing software video decode
        # on the CPU.  On Phoenix iGPU that means multi-stream Firefox
        # pegs the CPU into thermal throttle.
        enable = true;
        enable32Bit = true;  # Needed for Steam
        extraPackages = with pkgs; [
          # libglvnd provides the dispatcher libs (libGL.so.1, libEGL.so.1,
          # libGLX.so.0) that Firefox's glxtest dlopens.  NixOS's mesa is
          # built with -Dglvnd=enabled so mesa itself does NOT provide
          # libGL.so.1 — it only provides the mesa backends (libGLX_mesa.so,
          # libEGL_mesa.so).  Without libglvnd, glxtest errors out and
          # gfxInfo blocklists DMA-BUF, defeating VAAPI.
          libglvnd
          # pciutils for libpci.so — glxtest uses it to query the GPU.
          pciutils
          libva
          libva-utils
          egl-wayland
        ];
      };
    };

    environment.systemPackages = [
      # Used to test that rocmPackages above working properly
      pkgs.clinfo
      pkgs.lact
    ];

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
