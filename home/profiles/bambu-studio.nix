{ inputs, pkgs,  ... }:

let
  # bambu-studio = pkgs.callPackage ../../pkgs/bambu-studio { };
  # bambu-studio = pkgs.libsForQt5.callPackage ../pkgs/bambu-studio-compiled {};

  bambu-studio = pkgs.callPackage ../../pkgs/bambu-studio-hyprland { inputs = inputs; };
in
{
  home.packages = [
    bambu-studio
  ];
  xdg.mimeApps = {
    enable = true;
    # Make sure VSCode doesn't take over file mimetype
    associations.added = {
      "x-scheme-handler/bambustudio" = [ "bambu-studio.desktop" ];
    };
    defaultApplications = {
      "x-scheme-handler/bambustudio" = [ "bambu-studio.desktop" ];
    };
  };
}
