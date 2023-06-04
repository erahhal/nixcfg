let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/778525fd49bc8a68d9b5b88314b5af1786736c3b.tar.gz";
    sha256 = "0ch84fjna9ybdw47w1c4hgn9fvc3d1f88qdngc66fn0h33rjcwiw";
  }) { };

  python-with-packages = pkgs.python2.withPackages (p: with p; [
    virtualenv
  ]);
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    python-with-packages
  ];
}
