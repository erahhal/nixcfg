{ pkgs, ... }:
let
  pname = "bcompare";
  version = "5.0.0.29328";
  bcompare-beta = final: prev: {
    bcompare-beta = prev.unstable.bcompare.overrideAttrs (old: {
      src = pkgs.fetchurl {
        url = "https://www.scootersoftware.com/files/${pname}-${version}_amd64.deb";
        sha256 = "sha256-8rzU+rzhf875WNYFVSQGCGE5yewkLy9NalZaLm355I4=";
      };

      buildInputs = with pkgs.unstable; old.buildInputs or [] ++ [
        qt5.qtbase
        libsForQt5.poppler
        poppler_utils
        gvfs
        bzip2
      ];

      nativeBuildInputs = old.nativeBuildInputs or [] ++ [ pkgs.unstable.qt5.wrapQtAppsHook ];
      dontWrapQtApps = false;
    });
  };
in
{
  nixpkgs.overlays = [ bcompare-beta ];
}
