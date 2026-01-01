{ lib, rustPlatform, fetchFromGitHub, pkg-config, openssl, llvmPackages }:

rustPlatform.buildRustPackage rec {
  pname = "debouncer-udevmon";
  version = "unstable-2024-12-31";

  src = fetchFromGitHub {
    owner = "cppHusky";
    repo = "debouncer-udevmon";
    rev = "bdacc8c6bb14e1f8ce7fcfacac8c93c74905134a";
    hash = "sha256-OoKdgDxJNbAA3Ey42NPMT0cs+G4w6arJY/Pq26Z3qEA=";
  };

  cargoHash = "sha256-eGP1XpurdY8j/piONvS5w5R3uiDoH2QcISIMB8v8Ya4=";

  nativeBuildInputs = [ pkg-config llvmPackages.clang ];
  buildInputs = [ openssl ];

  LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";

  meta = with lib; {
    description = "Linux keyboard debouncer for interception-tools";
    homepage = "https://github.com/cppHusky/debouncer-udevmon";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "debouncer-udevmon";
  };
}
