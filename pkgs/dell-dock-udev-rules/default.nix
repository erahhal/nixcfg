{ lib, stdenv }:

## Usage
# In NixOS, simply add this package to services.udev.packages:
#   services.udev.packages = [ pkgs.dell-dock-udev-rules ];

stdenv.mkDerivation rec {
  pname = "dell-dock-udev-rules";
  version = "1";

  src = ''
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="a4:4c:c8:c1:50:de", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="dock_eth0"
  '';

  phases = [ "installPhase" ];

  installPhase = ''
    runHook preInstall
    echo $src > 20-dell-dock.rules
    mkdir -p $out/lib/udev/rules.d
    install -D 20-dell-dock.rules $out/lib/udev/rules.d/20-dell-dock.rules
    runHook postInstall
  '';

  meta = with lib; {
    description = "Dell dock udev rules";
    platforms = platforms.linux;
  };
}
