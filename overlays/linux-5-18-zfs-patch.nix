# @TODO: Remove this once fixed by ZFS upstream
#
# Issue:          https://github.com/NixOS/nixpkgs/issues/179551
# Overlay from:   https://gist.github.com/mpasternacki/819b7ff33c0df3f37b5687cfdeabf954
{ lib, pkgs, stdenv, ... }:

let linux518ZfsPatch = final: prev: {
  linuxPackages_5_18 = prev.linuxPackages_5_18.extend (lpself: lpsuper: {
    zfsUnstable = lpsuper.zfsUnstable.overrideAttrs
      (old: { patches = old.patches ++ [ ./zfs-2.1.5.patch ]; });
  });
};
in
{
  nixpkgs.overlays = [ linux518ZfsPatch ];
}
