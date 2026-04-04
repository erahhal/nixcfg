{ lib, pkgs, ... }:

package: pkgs.runCommandLocal (package.pname or package.name) { meta.broken = true; } (lib.warn "Package ${package.pname or package.name} is currently broken" "mkdir -p $out")
