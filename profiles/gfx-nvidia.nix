{ config, lib, pkgs, ... }:

# See: https://nixos.wiki/wiki/Nvidia

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only

    ## experimental
    # export WLR_RENDERER=vulkan
    # export GBM_BACKEND=nvidia-drm
    ## maybe helps with stutters
    export __GL_GSYNC_ALLOWED=0
    export __GL_VRR_ALLOWED=0

    exec -a "$0" "$@"
  '';
in
{
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" "bbswitch" ];

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  services.xserver = {
    # @TODO: Are these still needed?
    screenSection = ''
      Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
      Option         "AllowIndirectGLXProtocol" "off"
      Option         "TripleBuffer" "on"
    '';
  };

  environment.systemPackages = [
    pkgs.intel-gpu-tools
    nvidia-offload
  ];

  # vga=0, rdblacklist=nouveau, and nouveau.modeset=0 fix issue with external screens not turning on
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "vga=0"
    "rdblacklist=nouveau"
    "nouveau.modeset=0"

    ## These don't seem to make screen wake issues better
    # "acpi_osi=!"
    # "\"acpi_osi=Windows 2015\""
  ];

  hardware.bumblebee.enable = false;

  hardware.nvidia = {
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    # package = pkgs.linuxKernel.packages.linux_6_2.nvidia_x11_beta;
    nvidiaPersistenced = true;
    modesetting.enable = true;
    prime = {
      # sync.enable = true;
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}

