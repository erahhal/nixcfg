# Taken from Colemickens
# https://github.com/colemickens/nixcfg/blob/93e3d13b42e2a0a651ec3fbe26f3b98ddfdd7ab9/mixins/gfx-intel.nix

{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.hostParams.gpu.intel.enable {
    environment.systemPackages = with pkgs; [
      intel-gpu-tools
      libva-utils
      intel-media-driver
    ];

    # From: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel/default.nix
    # environment.variables = {
    #   VDPAU_DRIVER = lib.mkIf config.hardware.graphics.enable (lib.mkDefault "va_gl");
    # };
    environment.variables = {
       LIBVA_DRIVER_NAME = lib.mkIf config.hardware.graphics.enable ( lib.mkDefault "iHD" );
       # LIBVA_DRIVER_NAME = lib.mkIf config.hardware.graphics.enable ( lib.mkDefault "i965" );
    };

    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override {
        enableHybridCodec = true;
      };
    };

    hardware = {
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          vpl-gpu-rt          # for newer GPUs on NixOS >24.05 or unstable
          intel-media-driver # LIBVA_DRIVER_NAME=iHD
          # intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
          #libvdpau-va-gl

          # intel-media-driver
          # libva-vdpau-driver
          libvdpau-va-gl

          ## should this be used?
          ## Enabling it causes a nix build conflict with intel-vaapi-driver even though it's not installed explicitly
          # vaapiIntel

          ## Should this really be used instead? seems to already be installed by enabling GL
          # intel-vaapi-driver
        ];

        extraPackages32 = with pkgs.pkgsi686Linux; [
          intel-media-driver
          # intel-vaapi-driver
          libvdpau-va-gl
        ];
      };
    };

    ## These settings seem to slow down the desktop
    # services.xserver = {
    #   videoDrivers = [ "modesetting" ];
    #   deviceSection = ''
    #       Option "TearFree" "true"
    #       Option "AccelMod" "uxa"
    #       Option "DRI" "3"
    #   '';
    #   useGlamor = true;
    # };
  };
}
