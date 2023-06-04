{ config, pkgs, ... }:
{
  imports = [ ../modules/unifi.nix ];

  disabledModules = [ "services/networking/unifi.nix" ];

  nixpkgs.config = {
    packageOverrides = pkgs: {
      unifi = pkgs.erahhal.unifi;
    }; 
  };

  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi6;
    # unifiPackage = pkgs.unifi7;
  };
}
