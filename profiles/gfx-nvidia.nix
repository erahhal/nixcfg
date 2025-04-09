{ config, lib, pkgs, userParams, ... }:

# See: https://nixos.wiki/wiki/Nvidia

let
  truecrack-cuda = pkgs.callPackage ../pkgs/truecrack-cuda { };
  package = config.boot.kernelPackages.nvidiaPackages.stable;
in
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      ## creates missing nvidia_gbm.so file
      # (runCommand "nvidia-gbm-wrapper" { 
      #   buildInputs = [ package ]; } ''
      #   mkdir -p $out/lib/gbm
      #   # Create an absolute symlink to the nvidia-drm_gbm.so file from the nvidia_x11 package
      #   ln -s ${package}/lib/gbm/nvidia-drm_gbm.so $out/lib/gbm/nvidia_gbm.so
      # '')
      libvdpau-va-gl
      vaapiVdpau
      libva
      vulkan-loader
      vulkan-validation-layers
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs; [
      libvdpau-va-gl
      vaapiVdpau
      libva
      vulkan-loader
      vulkan-validation-layers
      libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # boot.kernelModules = [ "nvidia-uvm" ];

  boot.blacklistedKernelModules = [ "nouveau" "bbswitch" ];

  # services.xserver = {
  #   # @TODO: Are these still needed?
  #   screenSection = ''
  #     Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
  #     Option         "AllowIndirectGLXProtocol" "off"
  #     Option         "TripleBuffer" "on"
  #   '';
  # };

  environment.systemPackages = with pkgs; [
    # intel-gpu-tools
    # primus
    # truecrack-cuda
    # unstable.cudaPackages_12_3.cudatoolkit
    libglvnd
    libdrm
    mesa
    vulkan-loader
    vulkan-tools
    vulkan-validation-layers
  ];

  # vga=0, rdblacklist=nouveau, and nouveau.modeset=0 fix issue with external screens not turning on
  boot.kernelParams = [
    "vga=0"
    "rdblacklist=nouveau"
    "nouveau.modeset=0"
    ## Supposedly solves issues with corrupted desktop / videos after waking
    ## See: https://wiki.hyprland.org/Nvidia/
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

    ## These don't seem to make screen wake issues better
    # "acpi_osi=!"
    # "\"acpi_osi=Windows 2015\""
  ];

  hardware.bumblebee.enable = false;

  hardware.nvidia = {
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    # package = config.boot.kernelPackages.nvidiaPackages.latest;
    package = package;

    # nvidiaPersistenced = true;

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # powerManagement.enable = false;

    ## Hyprland config now recommends this
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Open source kernel module doesn't work with old card in Dell laptop

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Do not disable this unless your GPU is unsupported or if you have a good reason to.
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # !!! PRIME Sync and Offload Mode cannot be enabled at the same time.
    prime = {
      ## sync introduces better performance and greatly reduces screen tearing, at the
      ## expense of higher power consumption since the Nvidia GPU will not go to sleep
      ## completely unless called for, as is the case in Offload Mode.

      # sync.enable = true;

      ## With Reverse Prime the primary rendering device is the device's APU and the
      ## NVIDIA GPU acts as an offload device. This is done while also allowing to use
      ## the video outputs connected to the NVIDIA device. Additionally, this might use
      ## less power than Prime Sync since the more power efficient APU does most of the
      ## rendering, thus, allowing the NVIDIA card to sleep where possible.

      # reverseSync.enable = true;

      offload.enable = true;
      offload.enableOffloadCmd = true;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  ## Generate different boot profiles when rebuilding your system.
  ## Enable PRIME sync by default, but also create a "on-the-go"
  ## specialization that disables PRIME sync and instead enables offload mode.
  ## @TODO: Currently broken when built with latest ZFS kernel

  # specialisation = {
  #   on-the-go.configuration = {
  #     system.nixos.tags = [ "on-the-go" ];
  #     hardware.nvidia = {
  #       prime.offload.enable = lib.mkForce true;
  #       prime.offload.enableOffloadCmd = lib.mkForce true;
  #       prime.sync.enable = lib.mkForce false;
  #       prime.reverseSync.enable = lib.mkForce false;
  #     };
  #   };
  # };

  home-manager.users.${userParams.username} = { pkgs, ... }: {
    home.sessionVariables = {
      # GBM_BACKEND = "nvidia-drm";
      GBM_BACKEND = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}

