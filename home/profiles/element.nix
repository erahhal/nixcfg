# Temporary fix for the following crash:
# https://github.com/NixOS/nixpkgs/issues/238416

{ pkgs, ... }:
let
  elementFix = pkgs.element-desktop.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/element-desktop \
        --unset NIXOS_OZONE_WL
    '';
  });
in
{
  home.packages = [
    elementFix
  ];
}
