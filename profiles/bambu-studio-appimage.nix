{ lib, pkgs, ... }:

let
  pname = "bambu-studio";
  version = "02.04.00.70";
  ubuntu_version = "24.04_PR-8834";
  src = pkgs.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
    sha256 = "sha256-JrwH3MsE3y5GKx4Do3ZlCSAcRuJzEqFYRPb11/3x3r0=";
  };
  appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
  bambu-studio-appimage = pkgs.appimageTools.wrapType2 rec {
    inherit pname version src;
    name = "BambuStudio";

    profile = ''
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/"

      # GPU/Graphics settings (adjust based on your GPU)
      export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
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

    buildInputs = [ pkgs.makeWrapper ];

    extraInstallCommands = ''
      # Fix the desktop file to point to the correct binary
      install -m 444 -D ${appimageContents}/${name}.desktop $out/share/applications/${pname}.desktop

      # Replace the Exec line in the desktop file to point to our wrapped binary
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace "Exec=AppRun" "Exec=$out/bin/${pname}"

      # Install icon
      install -m 444 -D ${appimageContents}/${name}.png $out/share/icons/hicolor/512x512/apps/${name}.png
    '';

    meta = {
      description = "BambuStudio";
      homepage = "https://bambulab.com";
      downloadPage = "https://bambulab.com/en/download/studio";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  nixpkgs.config.packageOverrides = {
    bambu-studio = bambu-studio-appimage;
  };

  networking.firewall.extraCommands = ''
    iptables -I INPUT -m pkttype --pkt-type multicast -j ACCEPT
    iptables -A INPUT -m pkttype --pkt-type multicast -j ACCEPT
    iptables -I INPUT -p udp -m udp --match multiport --dports 1990,2021 -j ACCEPT
  '';
}
