# Brave from the brave-browser-nix input (see flake.nix), since nixpkgs no
# longer has it. Built with final.callPackage against OUR nixpkgs, like
# claude-code -- the input's own nixpkgs is never used.
#
# mkBefore: modules/desktop/chromium-based-apps wraps `prev.brave` with our
# flags, so this overlay must come ahead of it. Without the ordering, the
# wrapper would see nixpkgs' removed-package throw instead.
{ inputs, lib, ... }:
{
  nixpkgs.overlays = lib.mkBefore [
    (final: prev: {
      inherit (final.callPackage "${inputs.brave-browser-nix}/brave" { }) brave;
    })
  ];
}
