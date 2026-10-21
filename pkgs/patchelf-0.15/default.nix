# TEMPORARY: patchelf 0.19.2 (stdenv's default since the 2026-10-20 nixpkgs
# bump; 0.15.2 before it) aborts with `shiftFile: Assertion 'splitIndex == -1'
# failed` when it has to grow some prebuilt binaries' dynamic sections
# (NixOS/patchelf#583, open). Hit by HyperBackupExplorer (--set-rpath) and
# astrill (--add-rpath); 0.15.2 patches both cleanly with the same call
# sequence. Callers put this first on PATH in preFixup, since stdenv's
# --shrink-rpath, autoPatchelfHook and hand-written hooks all run `patchelf`
# from PATH. Delete this and those preFixup lines once a fixed patchelf
# reaches nixos-unstable.
{ patchelf, fetchurl }:

patchelf.overrideAttrs {
  version = "0.15.2";
  src = fetchurl {
    url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
    hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
  };
  doCheck = false;
}
