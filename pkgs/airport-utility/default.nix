{
  lib,
  stdenvNoCC,
  fetchurl,
  p7zip,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  winePackages,
  winetricks,
  cabextract,
  # Fallback Wine logical DPI for the x11 backend (96 = 100%, 192 = 200%). The
  # default Wayland backend scales via the compositor and ignores this. Override
  # per host via callPackage, or at runtime with AIRPORT_UTILITY_DPI.
  dpi ? 96,
}:

# Apple's AirPort Utility has no Linux build. 5.6.1 is the last version that can
# manage the "classic" base stations (the modern macOS/iOS utility dropped them),
# and it runs under Wine. There is no upstream Nix flake for it, so we package
# Apple's Windows installer directly: extract the MSI payloads at build time and
# install them into a per-user Wine prefix on first launch (see airport-utility.sh).
let
  # APUtil.exe is 32-bit and runs best in a 32-bit prefix, which is also the
  # historically recommended Wine mode for it. Use the plain 32-bit build: the
  # WoW64 (wineWowPackages) variants aren't on the binary cache and would
  # compile Wine from source.
  wine = winePackages.stable;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "airport-utility";
  version = "5.6.1.2";

  src = fetchurl {
    url = "https://download.info.apple.com/Mac_OS_X/041-0257.20120611.MkI85/AirPortSetup.exe";
    hash = "sha256-9fV4zykavEK6Uz54u9svUb9yYgAOJVsZXxcUn1VIZ1Q=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    p7zip
    makeWrapper
    copyDesktopItems
  ];

  installPhase = ''
    runHook preInstall

    # Pull the MSI payloads we need out of Apple's self-extracting installer
    # (AirPort.msi is the utility; Bonjour.msi is the 32-bit mDNS stack used to
    # discover base stations). Bonjour64.msi is skipped: the prefix is 32-bit.
    mkdir -p "$out/share/airport-utility"
    7z x -y "$src" AirPort.msi Bonjour.msi -o"$out/share/airport-utility"

    install -Dm755 ${./airport-utility.sh} "$out/bin/.airport-utility-wrapped"
    patchShebangs "$out/bin/.airport-utility-wrapped"
    makeWrapper "$out/bin/.airport-utility-wrapped" "$out/bin/airport-utility" \
      --prefix PATH : ${lib.makeBinPath [ wine winetricks p7zip cabextract ]} \
      --set MSIDIR "$out/share/airport-utility" \
      --set-default AIRPORT_UTILITY_DPI "${toString dpi}"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "airport-utility";
      exec = "airport-utility";
      desktopName = "AirPort Utility";
      comment = "Configure classic Apple AirPort base stations (5.6.1, via Wine)";
      categories = [ "Network" "System" ];
    })
  ];

  meta = {
    description = "Apple AirPort Utility 5.6.1 for configuring classic AirPort base stations, run under Wine";
    homepage = "https://support.apple.com/en-us/106400";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "airport-utility";
  };
})
