{ lib, gccStdenv, fetchFromGitHub, pkgs, cudatoolkit, addOpenGLRunpath
, pkg-config }:

  gccStdenv.mkDerivation rec {
  pname = "truecrack-cuda";
  version = "master";

  src = fetchFromGitHub {
    owner = "erahhal";
    repo = "truecrack";
    rev = version;
    sha256 = "1bkk8403r858ca9z87lav5mzgk9j5nxr3crfhz07zr44bnkiszpp";
  };

  configureFlags = [
    # "--with-cuda=${pkgs.unstable.cudaPackages_12_3.cudatoolkit}"
    "--with-cuda=${cudatoolkit}"
  ];

  nativeBuildInputs = [
    pkg-config
    addOpenGLRunpath
    # pkgs.unstable.cudaPackages_12_3.cuda_nvcc
    pkgs.cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    # pkgs.unstable.cudaPackages_12_3.cudatoolkit
    cudatoolkit
  ];

  ## No longer needed - code is patched
  # env.NIX_CFLAGS_COMPILE = "-fcommon";

  NIX_LDFLAGS = "-rpath ${pkgs.stdenv.cc.cc.lib}/lib";

  installFlags = [ "prefix=$(out)" ];
  enableParallelBuilding = true;

  # Set RUNPATH so that libcuda and libnvrtc in /run/opengl-driver(-32)/lib can be
  # found. See the explanation in libglvnd.
  postFixup = ''
    isELF "$out/bin/truecrack" || continue
    addOpenGLRunpath "$out/bin/truecrack"
  '';

  meta = with lib; {
    description = "TrueCrack is a brute-force password cracker for TrueCrypt volumes. It works on Linux and it is optimized for Nvidia Cuda technology.";
    homepage = "https://gitlab.com/kalilinux/packages/truecrack";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ erahhal ];
  };
}
