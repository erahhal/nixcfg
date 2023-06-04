{ pkgs, stdenv }:

let
  abstractdark = pkgs.callPackage ./abstractdark {};
  aerial = pkgs.callPackage ./aerial {};
  chili = pkgs.callPackage ./chili {};
  lain-wired = pkgs.callPackage ./lain-wired {};
  rokin05 = pkgs.callPackage ./rokin05 {};
  slice = pkgs.callPackage ./slice {};
  sugar-dark = pkgs.callPackage ./sugar-dark {};
in
pkgs.symlinkJoin {
  name = "sddm-themes";
  paths = [ 
    pkgs.qt5.qtgraphicaleffects
    pkgs.qt5.qtmultimedia

    abstractdark 
    aerial
    chili
    lain-wired
    rokin05 # multiple themes: adapta, arc, goodnight, mount, sober, zune
    slice
    sugar-dark 
  ];
}
