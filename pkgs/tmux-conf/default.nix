{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "tmux-conf";
  version = "c318d0834ffaa200ec959d812225da5aa191bee8";

  src = fetchFromGitHub {
    owner = "gpakosz";
    repo = ".tmux";
    rev = version;
    sha256 = "1dsh2985gvjwpaxqjxdkw3cdq63a2cs8p4x4y0ph3pf1y3cdi818";
  };

  # If phases is defined, it only runs the listed phases
  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  patches = [
    ./spacer-update.patch
  ];

  # Hooks allow overlays/overrides to modify things pre and post install
  installPhase = ''
    runHook preInstall

    mkdir -p $out/
    # Note that it's copying from . rather than $src
    # Patches are NOT applied inline to $src
    cp ./.tmux.conf $out/.tmux.conf
    cp ./.tmux.conf.local $out/.tmux.conf.local

    runHook postInstall
  '';

  meta = with lib; {
    description = "Patched pretty tmux configs";
    platforms = platforms.linux;
  };
}
