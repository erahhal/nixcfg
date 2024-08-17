## See: https://nixos.wiki/wiki/AMD_GPU

{ pkgs, ... }:
{
  ## Use AMD GPU from the start
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware = {
    opengl = {
      # Needed for Steam
      driSupport32Bit = true;
    };
  };

  environment.systemPackages = [
    # Used to test that rocmPackages above working properly
    pkgs.clinfo
  ];
}
