{ lib
, stdenvNoCC
, fetchFromGitHub
, makeWrapper
, python3
, callPackage
# Runtime helpers -- propagated onto PATH of the wrapper.
, pulseaudio  # parec (default audio source)
, sox         # alternative audio source
, pipewire    # pw-cat (preferred when pipewire is running)
, ydotool     # default Wayland input-simulation backend
, xdotool     # for X11 sessions
, wtype       # lightweight Wayland alternative
, procps      # pgrep, used by the toggle script
}:

let
  # vosk isn't in nixpkgs; build it from the precompiled manylinux wheel
  # against the same python3 we're wrapping with.
  pythonEnv = python3.withPackages (ps: [
    (ps.callPackage ../vosk { })
  ]);
in
stdenvNoCC.mkDerivation rec {
  pname = "nerd-dictation";
  # unreleased; pinned to upstream HEAD (single-file Python script).
  version = "unstable-2025-01-26";

  src = fetchFromGitHub {
    owner = "ideasman42";
    repo = "nerd-dictation";
    rev = "41f372789c640e01bb6650339a78312661530843";
    hash = "sha256-xjaHrlJvk8bNvWp1VE4EAHi2VJlAutBxUgWB++3Qo+s=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ pythonEnv ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/nerd-dictation
    cp nerd-dictation $out/share/nerd-dictation/nerd-dictation.py

    makeWrapper ${pythonEnv.interpreter} $out/bin/nerd-dictation \
      --add-flags "$out/share/nerd-dictation/nerd-dictation.py" \
      --prefix PATH : ${lib.makeBinPath [
        pulseaudio pipewire sox
        ydotool xdotool wtype
        procps
      ]}
    runHook postInstall
  '';

  meta = {
    description = "Offline, low-latency speech to text for Linux (VOSK/Kaldi-based)";
    homepage = "https://github.com/ideasman42/nerd-dictation";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "nerd-dictation";
  };
}
