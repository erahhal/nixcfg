# Taken from Colemickens
# https://github.com/colemickens/nixcfg/blob/93e3d13b42e2a0a651ec3fbe26f3b98ddfdd7ab9/mixins/gfx-intel.nix

{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    libva-utils
  ];

  # From: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel/default.nix
  environment.variables = {
    VDPAU_DRIVER = lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {
      enableHybridCodec = true;
    };
  };

  hardware = {
    opengl = {
      enable = true;
      # Needed for Steam
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl

        ## should this be used?
        ## Enabling it causes a nix build conflict with intel-vaapi-driver even though it's not installed explicitly
        # vaapiIntel

        ## Should this really be used instead? seems to already be installed by enabling GL
        # intel-vaapi-driver
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
}
