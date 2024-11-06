{ stdenv
, lib
, builtins
, mkWindowsApp
, wine
, fetchurl
, makeDesktopItem
, makeDesktopIcon   # This comes with erosanix. It's a handy way to generate desktop icons.
, copyDesktopItems
, copyDesktopIcons  # This comes with erosanix. It's a handy way to generate desktop icons.
, unzip }:

let
  reg_entries = builtins.readFile ./logpixels.reg;
in
mkWindowsApp rec {
  inherit wine;

  pname = "remarkable";
  version = "2.11.0.182";

  src = fetchurl {
    url = "https://downloads.remarkable.com/desktop/production/win/reMarkable-${version}-win32.exe";
    sha256 = "0yff44mb2m6yz2ip92f21gkdm7jwjl70pc6i4qhm2m9azp00m20i";
  };

  # In most cases, you'll either be using an .exe or .zip as the src.
  # Even in the case of a .zip, you probably want to unpack with the launcher script.
  dontUnpack = true;

  # You need to set the WINEARCH, which can be either "win32" or "win64".
  # Note that the wine package you choose must be compatible with the Wine architecture.
  wineArch = "win64";

  nativeBuildInputs = [ copyDesktopItems copyDesktopIcons ];

  # This code will become part of the launcher script.
  # It will execute if the application needs to be installed,
  # which would happen either if the needed app layer doesn't exist,
  # or for some reason the needed Windows layer is missing, which would
  # invalidate the app layer.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  winAppInstall = ''
    tmpdir=$(mktemp -d)
    cat > $tmpdir/logpixels.reg<< EOF
${reg_entries}
EOF
    regedit $tmpdir/logpixels.reg
    rm -rf $tmpdir
    wine ${src}
  '';

  # This code will become part of the launcher script.
  # It will execute after winAppInstall (if needed)
  # to run the application.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  # Command line arguments are in $ARGS, not $@
  # You need to set up symlinks for any files/directories that need to be persisted.
  # To figure out what needs to be persisted, take at look at $(dirname $WINEPREFIX)/upper
  winAppRun = ''
    tmpdir=$(mktemp -d)
    cat > $tmpdir/logpixels.reg<< EOF
${reg_entries}
EOF
    # Set DPI to 0x80/128 (might be able to go a bit higher).
    regedit $tmpdir/logpixels.reg
    rm -rf $tmpdir

    # # Persistence path
    # cache_dir="$HOME/.cache/remarkable"
    # mkdir -p "$cache_dir/data/desktop"
    # mkdir -p "$cache_dir/local/desktop"
    # mkdir -p "$cache_dir/Cookies"
    # data_dir="drive_c/users/$USER/Application Data/remarkable"
    # local_dir="drive_c/users/$USER/Local Settings/Application Data/remarkable"
    # cookies_dir="drive_c/users/$USER/Cookies"

    # ln -sf "$cache_dir/data" "$WINEPREFIX/$data_dir"
    # ln -sf "$cache_dir/local" "$WINEPREFIX/$local_dir"
    # rm -rf "$WINEPREFIX/$cookies_dir"
    # ln -sf "$cache_dir/Cookies" "$WINEPREFIX/$cookies_dir"
    # cp -n "$WINEPREFIX/user.reg" "$cache_dir/"
    # rm -rf "$WINEPREFIX/user.reg"
    # ln -sf "$cache_dir/user.reg" "$WINEPREFIX/user.reg"

    # # mkdir -p "$HOME/.wine/$data_dir/desktop"
    # # ln -sf "$HOME/.wine/$data_dir" "$WINEPREFIX/$data_dir"
    # # mkdir -p "$HOME/.wine/$local_dir/desktop"
    # # ln -sf "$HOME/.wine/$local_dir" "$WINEPREFIX/$local_dir"
    # # rm -rf "$WINEPREFIX/$cookies_dir"
    # # ln -sf "$HOME/.wine/$cookies_dir" "$WINEPREFIX/$cookies_dir"
    # # rm -rf "$WINEPREFIX/system.reg"
    # # ln -sf "$HOME/.wine/system.reg" "$WINEPREFIX/system.reg"
    # # rm -rf "$WINEPREFIX/user.reg"
    # # ln -sf "$HOME/.wine/user.reg" "$WINEPREFIX/user.reg"
    # # rm -rf "$WINEPREFIX/userdef.reg"
    # # ln -sf "$HOME/.wine/userdef.reg" "$WINEPREFIX/userdef.reg"

    rm -rf "$WINEPREFIX/drive_c/users"
    ln -sf "$HOME/.wine/drive_c/users" "$WINEPREFIX/drive_c/uesrs"
    rm -rf "$WINEPREFIX/system.reg"
    ln -sf "$HOME/.wine/system.reg" "$WINEPREFIX/system.reg"
    rm -rf "$WINEPREFIX/user.reg"
    ln -sf "$HOME/.wine/user.reg" "$WINEPREFIX/user.reg"
    rm -rf "$WINEPREFIX/userdef.reg"
    ln -sf "$HOME/.wine/userdef.reg" "$WINEPREFIX/userdef.reg"

    # Run app
    binpath="$WINEPREFIX/drive_c/Program Files (x86)/reMarkable"
    wine "$binpath/reMarkable.exe" "$ARGS"
  '';

  # This is a normal mkDerivation installPhase, with some caveats.
  # The launcher script will be installed at $out/bin/.launcher
  # DO NOT DELETE OR RENAME the launcher. Instead, link to it as shown.
  installPhase = ''
    runHook preInstall

    ln -s $out/bin/.launcher $out/bin/${pname}

    runHook postInstall
  '';

  desktopItems = let
    mimeTypes = [
                 "application/pdf"
                 "application/epub+zip"
               ];
  in [
    (makeDesktopItem {
      inherit mimeTypes;

      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Remarkable 2";
      genericName = "eInk Tablet App";
      categories = [
        "Office"
        "Graphics"
        "Viewer"
      ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = "remarkable";

    src = fetchurl {
      url = "https://images.ctfassets.net/9haz2glq4wt0/1yxsPvaCnwInqCpMNiIpSq/566258aaee87e7528980f027392a297e/reMarkable_Logo_Png.png";
      sha256 = "1nv4k268ib0pwyysl5mpsgdyyrnw990nnab6s4z67pbyiv6jxjmy";
      name = "remarkable.png";
    };
  };

  meta = with lib; {
    description = "Desktop app for interfacing with Remarkable 2 Tablet";
    homepage = "https://remarkable.com/";
    license = licenses.unfree;
    maintainers = with maintainers; [ erahhal ];
    platforms = [ "x86_64-linux" ];
  };
}
