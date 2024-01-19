# Taken from Colemickens
# https://github.com/colemickens/nixcfg/blob/93e3d13b42e2a0a651ec3fbe26f3b98ddfdd7ab9/mixins/gfx-intel.nix

{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    libva-utils
  ];
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {
      enableHybridCodec = true;
    };
  };
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl

        # vaapiIntel

        ## Should this really be used instead?
        intel-vaapi-driver
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
