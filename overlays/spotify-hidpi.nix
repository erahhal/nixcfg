{ pkgs, ... }:
let spotifyHidpi = final: prev: {
  spotify = prev.spotify.override {
    deviceScaleFactor = "1.75";
  };
};
in
{
  nixpkgs.overlays = [ spotifyHidpi ];
}
