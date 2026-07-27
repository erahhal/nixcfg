{ pkgs, ... }:
{
  # Jellyfin client that casts videos to mpv from the Jellyfin mobile/web app.
  # Packaged in nixpkgs (github.com/jellyfin/jellyfin-mpv-shim).
  home.packages = with pkgs; [
    jellyfin-mpv-shim
  ];
}
