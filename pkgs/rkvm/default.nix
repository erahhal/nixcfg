{ stdenv, lib, rustPlatform, fetchFromGitHub
, pkg-config, libevdev, openssl, llvmPackages, linuxHeaders
}:

rustPlatform.buildRustPackage rec {
  pname = "rkvm";
  version = "bf13366";

  src = fetchFromGitHub {
    owner = "htrefil";
    repo = "rkvm";
    rev = "bf133665eb446d9f128d02e4440cc67bce50f666";
    sha256 = "1j11lmrx8a8qicbh066j85qcdy5dwh21rf75cbj48g79ilpai9cx";
  };

  cargoSha256 = "sha256-K8pLltkd8dT69+LNMeUVF2bKDz9cLaiglfCSN0FgAgo=";

  nativeBuildInputs = [ llvmPackages.clang pkg-config openssl ];
  buildInputs = [ libevdev openssl linuxHeaders ];

  BINDGEN_EXTRA_CLANG_ARGS = "-I${lib.getDev libevdev}/include/libevdev-1.0";
  LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";

  # The libevdev bindings preserve comments from libev, some of which
  # contain indentation which Cargo tries to interpret as doc tests.
  doCheck = false;

  meta = with lib; {
    description = "Virtual KVM switch for Linux machines";
    homepage = "https://github.com/htrefil/rkvm";
    license = licenses.mit;
  };
}
