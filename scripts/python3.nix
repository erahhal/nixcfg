{ pkgs ? import <nixpkgs> {}, script-path }:
pkgs.mkShell {
  name = "python3-shell";
  # programs and libraries used at runtime
  buildInputs = with pkgs; [
    python3

    stdenv.cc.cc

    # For Numpy
    zlib

    # For rendering gym environments
    libGL
    libGLU
    xorg.libX11

    cairo
    gobject-introspection
    gtk2
    gtk3
    gtk4
    libjpeg
    libnotify
    pkg-config
  ];
  # programs and libraries used at compile time
  nativeBuildInputs = with pkgs; [
  ];
  # main host architecture packages - libraries and binaries
  targetPkgs = with pkgs; [
  ];
  # all architectures supported by host - libraries only
  multiPkgs = with pkgs; [
  ];
  shellHook = ''
    # for PyTorch
    export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib

    # for Numpy
    export LD_LIBRARY_PATH=${pkgs.zlib}/lib:$LD_LIBRARY_PATH

    # GL libraries (for gym environment rendering)
    export LD_LIBRARY_PATH=${pkgs.libGL}/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=${pkgs.libGLU}/lib:$LD_LIBRARY_PATH

    python -m venv venv
    source ./venv/bin/activate
  '';
}
