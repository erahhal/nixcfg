{ pkgs, ... }:

let
  bambu-studio-appimage = pkgs.appimageTools.wrapType2 rec {
    name = "BambuStudio";
    pname = "bambu-studio";
    version = "02.02.02.56";
    ubuntu_version = "24.04_PR-8184";

    src = pkgs.fetchurl {
      url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
      sha256 = "sha256-ziipEMz58lG/+uxubCd53c6BjJ9W3doJ9/Z8VJp+Za4=";
    };

    profile = ''
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/"
    '';

    extraPkgs = pkgs: with pkgs; [
      cacert
      glib
      glib-networking
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      webkitgtk_4_1
    ];
  };

  bambu-studio-appimage-wayland = pkgs.symlinkJoin {
    name = "bambu-studio";
    paths = [ bambu-studio-appimage ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/bambu-studio \
        --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json \
    '';
  };
in
{
  nixpkgs.config.packageOverrides = {
    bambu-studio = bambu-studio-appimage-wayland;
  };
}
