{ lib, pkgs, ... }:

let
  pname = "ubports-installer";
  version = "0.11.2";
  src = pkgs.fetchurl {
    url = "https://release-assets.githubusercontent.com/github-production-release-asset/81379180/71469a57-cbe2-44a7-8ce4-510b8b872661?sp=r&sv=2018-11-09&sr=b&spr=https&se=2025-10-14T18%3A39%3A15Z&rscd=attachment%3B+filename%3Dubports-installer_0.11.2_linux_x86_64.AppImage&rsct=application%2Foctet-stream&skoid=96c2d410-5711-43a1-aedd-ab1947aa7ab0&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skt=2025-10-14T17%3A38%3A16Z&ske=2025-10-14T18%3A39%3A15Z&sks=b&skv=2018-11-09&sig=N6AIV7qOhef7XGQmcsV7pMk7c2KYgKFj0l3PV1mRSl0%3D&jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmVsZWFzZS1hc3NldHMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwia2V5Ijoia2V5MSIsImV4cCI6MTc2MDQ2ODQ4MiwibmJmIjoxNzYwNDY0ODgyLCJwYXRoIjoicmVsZWFzZWFzc2V0cHJvZHVjdGlvbi5ibG9iLmNvcmUud2luZG93cy5uZXQifQ.YLesbHGtaCPaRf1b5T570WDresyYsh8_TDH56NY9_Wc&response-content-disposition=attachment%3B%20filename%3Dubports-installer_0.11.2_linux_x86_64.AppImage&response-content-type=application%2Foctet-stream";
    sha256 = "sha256-N22L+KnjjtGA9syo5aLldbP6K8IXV8CZ3trpYBxBSYY=";
  };
  appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
  udevrules = pkgs.writeText "99-ubports-installer.rules" ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0e79", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0502", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0b05", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="413c", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0489", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="091e", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0bb4", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="12d1", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="24e3", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2116", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0482", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="17ef", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1004", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0409", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2080", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0955", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2257", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="10a9", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1d4d", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0471", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04da", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="05c6", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1f53", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04dd", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fce", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0930", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="19d2", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2ae5", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2a45", MODE="0666", GROUP="plugdev"
  '';
  ubports-installer-appimage = pkgs.appimageTools.wrapType2 rec {
    inherit pname version src;
    name = "ubports-installer";

    passthru.buildNumber = "1";

    # extraPkgs = pkgs: with pkgs; [
    #   cacert
    #   glib
    #   glib-networking
    #   gst_all_1.gst-plugins-bad
    #   gst_all_1.gst-plugins-base
    #   gst_all_1.gst-plugins-good
    #   webkitgtk_4_1
    # ];

    buildInputs = [ pkgs.makeWrapper ];

    extraInstallCommands = ''
      # Fix the desktop file to point to the correct binary
      install -m 444 -D ${appimageContents}/${name}.desktop $out/share/applications/${pname}.desktop

      # Replace the Exec line in the desktop file to point to our wrapped binary
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace "Exec=AppRun --no-sandbox" "Exec=$out/bin/${pname}"

      # Install icon
      install -m 444 -D ${appimageContents}/${name}.png $out/share/icons/hicolor/512x512/apps/${name}.png

      # Install udev rules
      install -Dm644 ${udevrules} $out/lib/udev/rules.d/99-ubports-installer.rules
    '';

    meta = {
      description = "ubports";
      homepage = "https://ubuntu-touch.io";
      downloadPage = "https://devices.ubuntu-touch.io/installer/";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  nixpkgs.config.packageOverrides = {
    ubports-installer = ubports-installer-appimage;
  };

  services.udev.packages = [ ubports-installer-appimage ];
}
