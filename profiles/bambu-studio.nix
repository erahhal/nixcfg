# @TODO
# - convert into derivation / package
# - determine why runtimeInputs doesn't work

{ pkgs, userParams, ... }:
let
  version = "v01.08.01.57";
  filename = "BambuStudio_linux_ubuntu_${version}.AppImage";
  download_url = "https://github.com/bambulab/BambuStudio/releases/download/${version}/${filename}";
in
{
  home-manager.users.${userParams.username} = {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "bambu-studio";
        runtimeInputs = with pkgs; [
          webkitgtk
          glib-networking
          gst_all_1.gst-libav
        ];
        text = ''
          set +e
          export GIO_MODULE_DIR=${pkgs.glib-networking}/lib/gio/modules/

          # export GST_PLUGIN_PATH=${pkgs.gst_all_1.gst-libav}/lib/gstreamer-1.0
          export GST_PLUGIN_PATH=${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0

          LD_PRELOAD="${pkgs.webkitgtk}/lib/libwebkit2gtk-4.0.so.37"
          LD_PRELOAD="$LD_PRELOAD ${pkgs.webkitgtk}/lib/libjavascriptcoregtk-4.0.so.18"
          export LD_PRELOAD

          mkdir -p ~/AppImage
          cd ~/AppImage

          if [ ! -f "${filename}" ] || [ -f "${filename}.st" ]; then
            ${pkgs.axel}/bin/axel --timeout=10 -n 8 ${download_url}
          fi

          if [ -f "${filename}.st" ]; then
            echo "Download not finished. Please try again."
            exit 1
          fi

          ${pkgs.appimage-run}/bin/appimage-run "${filename}"
        '';
      })
    ];
  };
}
