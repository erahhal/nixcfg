{
  stdenv,
  lib,
  fetchFromGitHub,

  cmake,
  extra-cmake-modules,
  clang,
  git,
  gcc,
  # build-essential,
  # libgl1-mesa-dev,
  mesa,
  mesa_drivers,
  # m4,
  autoconf,
  # libwayland-dev,
  wayland,
  libxkbcommon,
  wayland-protocols,
  pkg-config,
  # libglu1-mesa-dev,
  libGLU,
  # libcairo2-dev,
  cairo,
  # libgtk-3-dev,
  gtk3,
  # libsoup2.4-dev,
  libsoup,
  # libwebkit2gtk-4.0-dev,
  webkitgtk,
  # libgstreamer1.0-dev,
  gst_all_1,
  # libgstreamer-plugins-good1.0-dev,
  # libgstreamer-plugins-base1.0-dev,
  # gstreamer1.0-plugins-bad,
  # libosmesa6-dev,

  ## @TODO: Check all deps above this line
  boost,
  tbb,
  openssl,
  curl,
  glew,
  glfw3,
  cereal,
  nlopt,
  openvdb,
  ilmbase,
  cgal,
  opencv,
  opencascade-occt,
  wxGTK32,
}:
stdenv.mkDerivation rec {
  pname = "bambu-studio";
  version = "01.09.01.58";

  src = fetchFromGitHub {
    owner = "bambulab";
    repo = "BambuStudio";
    rev = "v${version}";
    hash = "sha256-FvJLCHLqqHcUmkGyZWqPwoF10HsYXzHu4CgP0IxV1rc=";
  };

  cmakeFlags = [
    "-DwxWidgets_ROOT_DIR=${wxGTK32}"
    "-DwxWidgets_LIBRARIES=${wxGTK32}/lib"
  ];

  # programs and libraries used at compile time
  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    clang
    git
    gcc
    autoconf
    pkg-config
  ];

  #
  buildInputs = [
    mesa
    mesa_drivers
    wayland
    libxkbcommon
    wayland-protocols
    libGLU
    cairo
    gtk3
    libsoup
    webkitgtk
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad

    ## @TODO: Check all deps above this line
    boost
    tbb
    openssl
    curl
    glew
    glfw3
    cereal
    nlopt
    openvdb
    ilmbase
    cgal
    opencv
    opencascade-occt
    wxGTK32
  ];

  # preConfigure = ''
  #   export wxWidgets_LIBRARIES=${wxGTK32}/lib
  #   export wxWidgets_ROOT_DIR=${wxGTK32}
  #   mkdir build
  #   cd build
  #   cmake ../ -DDESTDIR="/home/_username_/work/projects/BambuStudio_dep" -DCMAKE_BUILD_TYPE=Release -DDEP_WX_GTK3=1
  #   make -j4
  #   cd ..
  #   mkdir  install_dir
  # '';

  configurePhase = ''
    runHook preConfigure
    # do nothing";
    runHook postConfigure
  '';


  buildPhase = ''
    mkdir BambuStudio_dep
    cd deps
    mkdir build
    cd build

    cmake ../ -DDESTDIR="../../BambuStudio_dep" -DCMAKE_BUILD_TYPE=Release -DDEP_WX_GTK3=1
    make -j4

    cd ../..

    mkdir install_dir
    mkdir build
    cd build

    cmake .. -DSLIC3R_STATIC=ON -DSLIC3R_GTK=3 -DBBL_RELEASE_TO_PUBLIC=1 -DCMAKE_PREFIX_PATH="../BambuStudio_dep/usr/local" -DCMAKE_INSTALL_PREFIX="../install_dir" -DCMAKE_BUILD_TYPE=Release
    cmake --build . --target install --config Release -j4
  '';

  meta = with lib; {
    description = "Bambu Lab Bambu Studio";
    homepage = "https://github.com/bambulab/BambuStudio";
    maintainers = with maintainers; [ erahhal ];
    license = licenses.agpl3Only;
    platforms = [
      "x86_64-linux"
    ];
  };
}
