{ pkgs, ... }:
let
  astrillvpn = pkgs.callPackage ../pkgs/astrillvpn {};
in
{

  environment.systemPackages = [
    astrillvpn
  ];

  imports = [
    ../modules/astrillvpn.nix
  ];

  services.astrillvpn.enable = true;
}
