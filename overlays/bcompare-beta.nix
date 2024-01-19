{ pkgs, ... }:
let
  pname = "bcompare";
  version = "5.0.0.28767";
  bcompare-beta = final: prev: {
    bcompare = prev.unstable.bcompare.overrideAttrs (old: {
      src = pkgs.fetchurl {
        url = "https://www.scootersoftware.com/files/${pname}-${version}_amd64.deb";
        sha256 = "sha256-/sM/IFNpA3IHoLHgyogHqny79fuERSn2OLPhvG+Zpbg=";
      };

      buildInputs = with pkgs.unstable; old.buildInputs or [] ++ [
        qt5.qtbase
        libsForQt5.poppler
        poppler_utils
        gvfs
        bzip2
      ];

      # nativeBuildInputs = old.nativeBuildInputs or [] ++ [ pkgs.unstable.qt5.wrapQtAppsHook ];
      # dontWrapQtApps = false;
    });
  };
in
{
  nixpkgs.overlays = [ bcompare-beta ];
}
