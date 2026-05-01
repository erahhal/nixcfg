{ lib
, buildPythonPackage
, fetchurl
, autoPatchelfHook
, stdenv
, cffi
, requests
, srt
, tqdm
, websockets
}:

# vosk is distributed only as a manylinux wheel with a precompiled libvosk.so
# that bundles a Kaldi-based streaming ASR engine. autoPatchelfHook fixes the
# RPATH so libstdc++ resolves against nixpkgs.
buildPythonPackage rec {
  pname = "vosk";
  version = "0.3.45";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/fc/ca/83398cfcd557360a3d7b2d732aee1c5f6999f68618d1645f38d53e14c9ff/vosk-${version}-py3-none-manylinux_2_12_x86_64.manylinux2010_x86_64.whl";
    hash = "sha256-JeAlCTxDmdcnj1Q1aO2MxUYKw6S/SMI2c6zh4l0mYZ8=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  propagatedBuildInputs = [
    cffi
    requests
    srt
    tqdm
    websockets
  ];

  pythonImportsCheck = [ "vosk" ];

  meta = {
    description = "Offline speech recognition API based on Kaldi (streaming, on-CPU)";
    homepage = "https://alphacephei.com/vosk/";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
