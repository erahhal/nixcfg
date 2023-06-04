{ pkgs, ... }:
let sddm-with-env = final: prev: {
  sddm = prev.sddm.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./sddm-with-env/wayland-session.patch
      # Xsession already has the appropriate sourcing
    ];

    ## To upgrade
    # version = "develop-0fp0v8lc";

    # src = pkgs.fetchFromGitHub {
    #   owner = "sddm";
    #   repo = "sddm";
    #   rev = "develop";
    #   sha256 = "0fp0v8lcrs77h7a2ajn1wxvfjzdny2p2h0lgnkmlwxg7n51dixhm";
    # };

    # # Get rid of patches
    # patches = [];
  });
};
in
{
  nixpkgs.overlays = [ sddm-with-env ];
}
