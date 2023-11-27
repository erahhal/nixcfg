# Temporary fix for the following crash:
# https://github.com/NixOS/nixpkgs/issues/238416

## Potential Workaround:
# https://github.com/vector-im/element-desktop/issues/1026

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
    ## Broken in wayland for now
    # elementFix
    pkgs.unstable.element-desktop
  ];
}
