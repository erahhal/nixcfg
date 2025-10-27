{ lib, pkgs, ... }:

package: pkgs.runCommandLocal package.pname { meta.broken = true; } (lib.warn "Package ${package.pname} is currently broken" "mkdir -p $out")
