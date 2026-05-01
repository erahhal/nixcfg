{ lib
, buildPythonPackage
, fetchurl
, autoPatchelfHook
, stdenv
, numpy
, sounddevice
, requests
, tqdm
, filelock
, platformdirs
, portaudio
}:

# Moonshine (Useful Sensors, 2024) -- a purpose-built low-latency streaming
# ASR model. Shipped as a precompiled manylinux wheel with a bundled ONNX
# Runtime shared object and a packaged "tiny-en" model (assets/tiny-en/).
# Larger / streaming / non-English models are downloaded on first use into
# ~/.cache/moonshine/.
#
# autoPatchelfHook fixes libstdc++ RPATH; the bundled libonnxruntime sitting
# next to libmoonshine.so is discovered via the wheel's `.libs/` dir.
buildPythonPackage rec {
  pname = "moonshine-voice";
  version = "0.0.59";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/7d/f7/84140df51fa82cf582e888ac7e7a57e94639bd8fa2e47a831ba93c39ebc7/moonshine_voice-${version}-py3-none-manylinux_2_34_x86_64.whl";
    hash = "sha256-Yx8/xLweqY7ZIag4fZFvpnS2BknPr4adlNGPE5PhkuY=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib  # libstdc++
    portaudio         # needed by sounddevice at runtime
  ];

  propagatedBuildInputs = [
    numpy
    sounddevice
    requests
    tqdm
    filelock
    platformdirs
  ];

  # autoPatchelfHook's strictDeps can't see the neighbour .so layout; disable
  # the RPATH check for the bundled onnxruntime (libmoonshine resolves it via
  # a relative path at import time).
  dontAutoPatchelf = false;
  autoPatchelfIgnoreMissingDeps = [ "libonnxruntime-13ab8084.so.1" ];

  pythonImportsCheck = [ "moonshine_voice" ];

  meta = {
    description = "Low-latency on-device streaming ASR (and TTS) library from Moonshine AI";
    homepage = "https://github.com/moonshine-ai/moonshine";
    license = with lib.licenses; [ mit ]; # Moonshine is MIT, bundled onnxruntime is MIT too
    platforms = [ "x86_64-linux" ];
  };
}
