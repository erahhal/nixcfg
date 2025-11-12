{ config, lib, pkgs, userParams, ... }:

# See: https://nixos.wiki/wiki/Nvidia

## @IMPORTANT NOTE: On Hybrid setup:
## - Internal display is driven by intel GPU
## - External display is driven by nvidia GPU
## - Rendering on intel and offloading to nvidia is slow on external monitors, especially high resolution ones.
## - Rendering on nvidia and offloading to intel is slow on laptop monitor, but tolerable
## - SO, make sure window manager is using discrete nvidia GPU to render

# BIOS hybrid/discrete GPU
# intel modules loaded/not loaded
# AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0", AQ_DRM_DEVICES = "/dev/dri/card1", AQ_DRM_DEVICES = "/dev/dri/card0";

# hybrid, modules loaded, "/dev/dri/card0:/dev/dri/card1"
#  - Hyprland works at all with external monitor
#  - Hyprland performance/animations smooth on external monitor
#  - Laptop display DPMS works
#  - Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  x Chromium-based apps use GPU
#  - GPU-based apps work at all
#  ? chrome hardware-based video encoding (e.g. filters on google meet)

# hybrid, modules loaded, "/dev/dri/card1:/dev/dri/card0"
#  - Hyprland works at all with external monitor
#  x Hyprland performance/animations smooth on external monitor
#  ~ Laptop display DPMS works
#  - Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  - Chromium-based apps use GPU
#  - GPU-based apps work at all

# hybrid, modules loaded, "/dev/dri/card0"
#  - Hyprland works at all with external monitor
#  - Hyprland performance/animations smooth on external monitor
#  - Laptop display DPMS works
#  - Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  x Chromium-based apps use GPU
#  - GPU-based apps work at all

# hybrid, modules loaded, "/dev/dri/card1"
#  x Hyprland works at all with external monitor
#  x Hyprland performance/animations smooth on external monitor
#  - Laptop display DPMS works
#  - Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  - Chromium-based apps use GPU
#  - GPU-based apps work at all

# hybrid, modules UNLOADED, "/dev/dri/card1"
#  - Hyprland works at all with external monitor
#  x Hyprland works at all with laptop display
#  - Hyprland performance/animations smooth on external monitor
#  - Laptop display DPMS works
#  x Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  - Chromium-based apps use GPU
#  - GPU-based apps work at all

# hybrid, modules UNLOADED, "/dev/dri/card0"
#  x Hyprland works at all with external monitor
#  x Hyprland works at all with laptop display
#  - Hyprland performance/animations smooth on external monitor
#  - Laptop display DPMS works
#  x Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  x Chromium-based apps use GPU
#  x GPU-based apps work at all

# hybrid, modules UNLOADED, "/dev/dri/card1:/dev/dri/card0"
#  - Hyprland works at all with external monitor
#  x Hyprland works at all with laptop display
#  x Hyprland performance/animations smooth on external monitor
#  - Laptop display DPMS works
#  x Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  x  Chromium-based apps use GPU
#  x  GPU-based apps work at all

# hybrid, modules UNLOADED, "/dev/dri/card0:/dev/dri/card1"
#  -  Hyprland works at all with external monitor
#  x  Hyprland works at all with laptop display
#  x  Hyprland performance/animations smooth on external monitor
#  x  Laptop display DPMS works
#  x  Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  x  Chromium-based apps use GPU
#  x  GPU-based apps work at all

# discrete, modules loaded, "/dev/dri/card0:/dev/dri/card1"
#   Hyprland works at all with external monitor
#   Hyprland performance/animations smooth on external monitor
#   Laptop display DPMS works
#   Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#   Chromium-based apps use GPU
#   GPU-based apps work at all

# discrete, modules loaded, "/dev/dri/card1:/dev/dri/card0"
#   Hyprland works at all with external monitor
#   Hyprland performance/animations smooth on external monitor
#   Laptop display DPMS works
#   Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#   Chromium-based apps use GPU
#   GPU-based apps work at all

# discrete, modules loaded, "/dev/dri/card0"
#   Hyprland works at all with external monitor
#   Hyprland performance/animations smooth on external monitor
#   Laptop display DPMS works
#   Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#   Chromium-based apps use GPU
#   GPU-based apps work at all

## !!!! SOLUTION
# discrete, modules loaded, "/dev/dri/card1"
#  - Hyprland works at all with external monitor
#  - Hyprland performance/animations smooth on external monitor
#  - Laptop display DPMS works
#  x Intel GPU used for basic rendering, with NVIDIA used for offload/special cases
#  - Chromium-based apps use GPU
#  - GPU-based apps work at all

let
  usingIntel = config.hostParams.gpu.intel.enable == true;
  disableIntelModules = config.hostParams.gpu.intel.enable == false && config.hostParams.gpu.intel.disableModules == true;
  truecrack-cuda = pkgs.callPackage ../pkgs/truecrack-cuda { };
  # package = config.boot.kernelPackages.nvidiaPackages.stable;
  package = config.boot.kernelPackages.nvidiaPackages.latest;
in
{
  config = lib.mkIf config.hostParams.gpu.nvidia.enable {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.nvidia.acceptLicense = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver           # VDPAU backend for VA-API
        libvdpau-va-gl       # VDPAU driver with VA-API/OpenGL backend
        vulkan-loader
        vulkan-validation-layers
        egl-wayland
        libva
        libva-utils
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        libva
        libva-utils
      ];
      # extraPackages = with pkgs; [
      #   # creates missing nvidia_gbm.so file
      #   (runCommand "nvidia-gbm-wrapper" {
      #     buildInputs = [ package ]; } ''
      #     mkdir -p $out/lib/gbm
      #     # Create an absolute symlink to the nvidia-drm_gbm.so file from the nvidia_x11 package
      #     ln -s ${package}/lib/gbm/nvidia-drm_gbm.so $out/lib/gbm/nvidia_gbm.so
      #   '')
      #   libvdpau-va-gl
      #   libva-vdpau-driver
      #   libva
      #   vulkan-loader
      #   vulkan-validation-layers
      #   nvidia-vaapi-driver
      # ];
      # extraPackages32 = with pkgs; [
      #   libvdpau-va-gl
      #   libva-vdpau-driver
      #   libva
      #   vulkan-loader
      #   vulkan-validation-layers
      #   libvdpau-va-gl
      #   nvidia-vaapi-driver
      # ];
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    ## Make sure this is loadedbefore the rest to avoid issues with chromium, according to Hyprland wiki
    boot.initrd.kernelModules = lib.mkIf (disableIntelModules == false) [ "i915" ];
    boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    ## Must blacklist intel modules if using nvidias as only GPU, otherwise external monitors are not available in Hyprland
    boot.blacklistedKernelModules = [ "nouveau" "bbswitch" ] ++ (if disableIntelModules then [ "i915" "xe" ] else []);
    # boot.blacklistedKernelModules = [ "nouveau" ];

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
      vdpauinfo
      libva-utils
    ];

    # # vga=0, rdblacklist=nouveau, and nouveau.modeset=0 fix issue with external screens not turning on
    boot.kernelParams = [
      "vga=0"
      "rdblacklist=nouveau"
      "nouveau.modeset=0"

      # Supposedly prevents 20-30 second handoff delay to compositor, but doesn't seem to work
      # Causes power management to be offloaded to CPU
      # Only works with proprietary driver (open = false)
      "nvidia.NVreg_EnableGpuFirmware=0"

      ## Supposedly solves issues with corrupted desktop / videos after waking
      ## See: https://wiki.hyprland.org/Nvidia/
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

      "nvidia.NVreg_UsePageAttributeTable=1" # why this isn't default is beyond me.
      "nvidia_modeset.disable_vrr_memclk_switch=1" # stop really high memclk when vrr is in use.

      (lib.mkIf config.hardware.nvidia.powerManagement.enable
        "nvidia.NVreg_TemporaryFilePath=/var/tmp" # store on disk, not /tmp which is on RAM
      )

      "nvidia-drm.modeset=1"

      ## Shouldn't be needed as it's set automatically with modeset=1 in latest drivers
      "nvidia-drm.fbdev=1"
    ] ++ (if disableIntelModules then [
      ## Adding to boot.blacklistedKernelModules is not enough
      "module_blacklist=nouveau,i915,xe"
    ] else [
      "module_blacklist=nouveau"
      ## Attempt to keep intel GPU clock rate up for fast offloading

      # ## may be useless or worse than useless on modern intel GPUs - just causes more power usage
      # "i915.enable_rc6=0"
      # ## Forces higher memory bandwidth usage
      # "i915.enable_fbc=0"
      # ## Significantly higher battery usage, but may help with sleep freezes
      # "i915.enable_dc=0"
      # ## The GuC and HuC firmware can improve GPU performance and power management for newer Intel graphics
      # "i915.enable_guc=3"
    ]);

    # hardware.bumblebee.enable = false;

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
      # open = true;
      open = false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # !!! PRIME Sync and Offload Mode cannot be enabled at the same time.
      prime = lib.mkIf usingIntel {
        ## sync introduces better performance and greatly reduces screen tearing, at the
        ## expense of higher power consumption since the Nvidia GPU will not go to sleep
        ## completely unless called for, as is the case in Offload Mode.

        # sync.enable = true;

        ## With Reverse Prime the primary rendering device is the device's APU and the
        ## NVIDIA GPU acts as an offload device. This is done while also allowing to use
        ## the video outputs connected to the NVIDIA device. Additionally, this might use
        ## less power than Prime Sync since the more power efficient APU does most of the
        ## rendering, thus, allowing the NVIDIA card to sleep where possible.

        reverseSync.enable = true;

        offload.enable = false;
        # offload.enable = true;
        # offload.enableOffloadCmd = true;

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
        ## Causes Niri to fail to load
        # __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        EGL_PLATFORM = "wayland";
        ## Tells chromium-based apps to use Wayland instead of X11
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        ## Should do the same thing as ELECTRON_OZONE_PLATFORM_HINT
        NIXOS_OZONE_WL = "1";

        # WLR_DRM_NO_ATOMIC = "1";
        # __VK_LAYER_NV_optimus = "NVIDIA_only";
        # NVD_BACKEND = "direct";

        ## Hyprland: Disable hardware mouse cursor to prevent GPU issues
        WLR_NO_HARDWARE_CURSORS = "1";
        # __GL_SYNC_TO_VBLANK = "1";
        # __GL_GSYNC_ALLOWED = "0";
        # __GL_VRR_ALLOWED = "0";
        # __GL_TRIPLE_BUFFER = "1";
      } // (if usingIntel then {
        ## Prioritize NVidia GPU (card 1) over Intel GPU for Hyprland
        AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
        ## For dual-gpu setup, deal with slowness/stuttering on external monitor due to memory copy between GPUs
        ## Doesn't seem to work.
        AQ_FORCE_LINEAR_BLIT = "1";

        ## Reverse PRIME for Niri - use intel GPU when possible
        __GLX_VENDOR_LIBRARY_NAME = lib.mkForce "mesa";
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        ## End reverse PRIME

      } else {
        ## Even with intel module not loaded, Nvidia device is still card1 instead of card0
        AQ_DRM_DEVICES = "/dev/dri/card1";
        # AQ_DRM_DEVICES = "/dev/dri/card0";
        # AQ_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
        # AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
      });
    };
  };
}

