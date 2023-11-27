{ lib, buildGoModule, fetchFromGitHub, ... }:

buildGoModule rec {
  pname = "totp";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "arcanericky";
    repo = "totp";
    rev = "v${version}";
    sha256 = "1dqrv3qy33hkn4avqkzhyg9g6flfnsirva7gvbk0xdymsmcddn9s";
  };

  vendorHash = "sha256-mnE+Kvif4v/RvDck1Gda4uS2gr9Ohj3MOfRcR67R2UY=";

  ## use the following to determine vendorHash:
  #  vendorHash = lib.fakeSha256;
  #  doCheck = false;
  ## then run the build and see what the value should be

  meta = with lib; {
    description = "A time-based one-time password (TOTP) code generator written in Go.";
    homepage = "https://github.com/arcanericky/totp";
    license = licenses.mit;
  };
}
