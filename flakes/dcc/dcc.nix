{ pkgs, stdenv, unzip, dpkg, bzip2, openssl, ... }:

let
  cc_version = "4.6.0-277";
  srvadmin_version = "9.5.0";
in
let
  dcc = stdenv.mkDerivation {
    pname = "dcc";
    version = cc_version;

    src = ./dcc.zip;

    buildInputs = [ unzip bzip2 dpkg ];

    phases = [ "installPhase" "fixupPhase" ];

    installPhase = ''
      unzip -P dell-blocks-downloads $src
      tar xvzf command-configure_${cc_version}.ubuntu20_amd64.tar.gz
      dpkg -x command-configure_${cc_version}.ubuntu20_amd64.deb command-configure
      dpkg -x srvadmin-hapi_${srvadmin_version}_amd64.deb srvadmin
      mkdir -p $out/bin
      cp command-configure/opt/dell/dcc/* $out/bin
      mkdir -p $out/lib
      cp srvadmin/opt/dell/srvadmin/lib64/* $out/lib
    '';

      postFixup = ''
        patchelf \
          --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          $out/bin/cctk
      '';
  };
  cctk-wrapper = pkgs.writeShellScriptBin "cctk-wrapper" ''
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${dcc}/lib:${dcc}/bin ${dcc}/bin/cctk
  '';
in
pkgs.buildFHSEnv {
  name = "cctk";
  targetPkgs = pkgs: with pkgs;
    [
      openssl.out
      cctk-wrapper
    ];
  runScript = "cctk-wrapper";
}
