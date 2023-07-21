{ pkgs, ... }:
let
  totp = pkgs.callPackage ../pkgs/totp { };
in
{
  environment.systemPackages = with pkgs; [
    totp
  ];
}
