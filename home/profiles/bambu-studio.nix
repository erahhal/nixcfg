{ pkgs,  ... }:

let
  bambu-studio = pkgs.callPackage ../../pkgs/bambu-studio { };
in
{
  home.packages = [ bambu-studio ];
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
