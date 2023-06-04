{ pkgs, ... }:
let pam-patched = final: prev: {
  pam = prev.pam.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./pam-patched/suid-wrapper-path.patch
    ];
  });
};
in
{
  nixpkgs.overlays = [ pam-patched ];
}
