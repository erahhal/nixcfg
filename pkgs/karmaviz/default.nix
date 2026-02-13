{ lib
, stdenv
, fetchFromGitHub
, python3
, makeWrapper
, mesa
, libGL
, libx11
, libxext
, alsa-lib
, pulseaudio
, pipewire
, qt5
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    pygame
    moderngl
    numpy
    pyqt5
    sounddevice
    scipy
    cython
  ]);
in
stdenv.mkDerivation rec {
  pname = "karmaviz";
  version = "unstable-2025-01-01";

  src = fetchFromGitHub {
    owner = "karmatripping";
    repo = "KarmaViz";
    rev = "67e8a15dda8cb7b5f052ade0731db3de62d82063";
    hash = "sha256-f2BIkp4UQt2OGFn+QrySXU/ZWgpi8/rWGvQaah6WXHs=";
  };

  nativeBuildInputs = [
    makeWrapper
    python3.pkgs.cython
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    mesa
    libGL
    libx11
    libxext
    alsa-lib
    pulseaudio
    pipewire
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/karmaviz $out/bin
    cp -r . $out/opt/karmaviz/

    # Build Cython extensions if setup.py exists
    if [ -f setup.py ]; then
      cd $out/opt/karmaviz
      ${pythonEnv}/bin/python setup.py build_ext --inplace || true
    fi

    makeWrapper ${pythonEnv}/bin/python $out/bin/karmaviz \
      --add-flags "$out/opt/karmaviz/main.py" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ mesa libGL ]}" \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins"

    runHook postInstall
  '';

  meta = with lib; {
    description = "GPU-accelerated audio visualizer for Linux with real-time GLSL shader compilation";
    homepage = "https://github.com/KarmaTripping/karmaviz";
    license = licenses.unfree;  # Commercial license required for non-personal use
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
