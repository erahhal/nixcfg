{ pkgs, lib, config }:
{ name, innerCommand, preCommands ? "" }:
let
  desktopParams = config.hostParams.desktop;

  runtimePaths = lib.makeBinPath [
    pkgs.niri
    pkgs.jq
    pkgs.gamescope
  ];

  script = pkgs.writeShellScriptBin name ''
    # Kill any existing Steam/gamescope and clean stale state
    ${pkgs.procps}/bin/pkill -x gamescope 2>/dev/null
    ${pkgs.procps}/bin/pkill -x steam 2>/dev/null
    sleep 1
    rm -f "$XDG_RUNTIME_DIR"/gamescope-* 2>/dev/null
    rm -f /tmp/.X*-lock 2>/dev/null
    rm -f /tmp/.X11-unix/X[1-9]* 2>/dev/null
    ${preCommands}
    EXIT_SIGNAL="$HOME/.local/share/Steam/.gamescope-exit"
    rm -f "$EXIT_SIGNAL"
    WIDTH=$(niri msg --json focused-output | jq '.modes[.current_mode].width')
    HEIGHT=$(niri msg --json focused-output | jq '.modes[.current_mode].height')
    INNER_W=$WIDTH
    INNER_H=$HEIGHT
    ${lib.optionalString desktopParams.gamescope.halveResolution ''
    if [ "$WIDTH" -gt ${toString desktopParams.gamescope.maxWidth} ] || [ "$HEIGHT" -gt ${toString desktopParams.gamescope.maxHeight} ]; then
      INNER_W=$((WIDTH / 2))
      INNER_H=$((HEIGHT / 2))
    fi
    ''}
    # Watch for exit signal from steamos-session-select (runs inside Flatpak sandbox).
    # When "Switch to Desktop" is clicked, the script touches the signal file.
    # This watcher kills gamescope from the host side since the sandbox can't.
    (while true; do
      if [ -f "$EXIT_SIGNAL" ]; then
        rm -f "$EXIT_SIGNAL"
        ${pkgs.procps}/bin/pkill -P $$ gamescope 2>/dev/null
        break
      fi
      sleep 0.5
    done) &
    WATCHER_PID=$!

    gamescope \
      --steam \
      --backend sdl \
      -W $WIDTH \
      -w $INNER_W \
      -H $HEIGHT \
      -h $INNER_H \
      --fullscreen \
      --grab \
      --force-grab-cursor \
      --cursor-scale-height $HEIGHT \
      --adaptive-sync \
      -- ${innerCommand}

    kill $WATCHER_PID 2>/dev/null
    rm -f "$EXIT_SIGNAL"
  '';
in
pkgs.stdenv.mkDerivation {
  inherit name;
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    install -Dm755 ${script}/bin/${name} $out/bin/${name}
    wrapProgram $out/bin/${name} \
      --suffix PATH : ${runtimePaths}
  '';
}
