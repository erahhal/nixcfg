{ lib
, stdenvNoCC
, python3
, makeWrapper
, writeShellApplication
, callPackage
, ydotool
, procps
, libnotify
# Flags baked into the dictate script; override by recursing through callPackage.
, modelArch ? 2   # TINY_STREAMING (downloaded on first run ~50 MB)
, language ? "en"
}:

let
  moonshine-voice = python3.pkgs.callPackage ../moonshine-voice { };

  pythonEnv = python3.withPackages (ps: [
    (ps.callPackage ../moonshine-voice { })
  ]);
in
writeShellApplication {
  name = "moonshine-dictate";
  runtimeInputs = [ pythonEnv ydotool procps libnotify ];
  # These are substituted at Nix evaluation time; the shell script below uses
  # them as fixed literals.
  text = ''
    # moonshine-dictate -- toggle-style push-to-talk dictation.
    #
    # First invocation: spawns `python -m moonshine_voice.mic_transcriber`,
    # streams its completed-line output into `ydotool type`, saves the pgid.
    # Second invocation: kills the pgid, tears everything down.
    #
    # Moonshine downloads the selected model on first run into
    #   $XDG_CACHE_HOME/moonshine-voice/  (typically ~/.cache/moonshine-voice/)
    # Subsequent runs are offline.

    set +e

    LANGUAGE=${lib.escapeShellArg language}
    MODEL_ARCH=${toString modelArch}

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    PIDFILE="$RUNTIME_DIR/moonshine-dictate.pgid"

    if [ -f "$PIDFILE" ]; then
      pgid="$(cat "$PIDFILE")"
      if kill -0 -- "-$pgid" 2>/dev/null; then
        # Graceful shutdown. We need SIGINT specifically because Moonshine's
        # mic_transcriber main block buffers a partial in-progress utterance
        # until Stream.stop() runs, and stop() only runs in the `finally:`
        # clause of a try/finally around its main loop. SIGTERM kills Python
        # without running `finally`, so anything the user was saying when
        # they tapped the hotkey to stop -- the most important utterance --
        # never hits stdout, never reaches our `ydotool type` loop, and
        # never appears in their editor. SIGINT (KeyboardInterrupt) DOES
        # trigger `finally`, which calls Stream.stop(), which flushes the
        # pending transcript and emits a final `on_line_completed` event.
        # Target the python process specifically (not the whole pgid) so the
        # while-read wrapper below it stays alive long enough to receive
        # that final line before it goes away.
        py_pid=$(pgrep -P "$pgid" -f 'mic_transcriber' | head -1)
        if [ -n "$py_pid" ]; then
          kill -INT "$py_pid" 2>/dev/null || true
          # Give python up to 2 s to run its finally block and flush.
          for _ in $(seq 1 40); do
            kill -0 "$py_pid" 2>/dev/null || break
            sleep 0.05
          done
        fi
        # Clean up any leftovers (the bash read-loop wrapper, any zombie
        # pw-cat/sounddevice pollers) now that the flush has drained.
        kill -TERM -- "-$pgid" 2>/dev/null || true
        rm -f "$PIDFILE"
        notify-send -t 1000 -a moonshine "moonshine" "■ stopped" 2>/dev/null || true
        exit 0
      fi
      rm -f "$PIDFILE"
    fi

    notify-send -t 1500 -a moonshine "moonshine" \
      "● listening ($LANGUAGE, arch $MODEL_ARCH)" 2>/dev/null || true

    # A small log lets us debug silent failures after the fact.
    LOGFILE="$RUNTIME_DIR/moonshine-dictate.log"
    : > "$LOGFILE"

    # Start the transcriber + typist pipeline in a new process group so we
    # can signal the whole thing with one `kill -- -<pgid>`.
    #
    # `python -u` + PYTHONUNBUFFERED=1: upstream mic_transcriber's FileListener
    # prints completed transcript lines without flush=True, so when stdout is
    # a pipe (as here) they stay in Python's block buffer and never reach the
    # downstream `ydotool type` loop. Forcing unbuffered IO makes streaming
    # dictation actually stream.
    # Keycodes: 29=LCtrl 97=RCtrl 42=LShift 54=RShift 56=LAlt 100=RAlt
    #           125=LSuper 126=RSuper. These are released before every
    #           type call so a still-depressed hotkey modifier can't turn
    #           typed letters into niri shortcuts (windows resizing,
    #           workspaces switching, etc).
    setsid bash -c "
      exec 2>>'$LOGFILE'
      PYTHONUNBUFFERED=1 python -u -m moonshine_voice.mic_transcriber \\
        --language $LANGUAGE \\
        --model-arch $MODEL_ARCH |
      while IFS= read -r line; do
        if [ -n \"\$line\" ]; then
          printf '%s\n' \"TYPING: \$line\" >> '$LOGFILE'
          ydotool key 29:0 97:0 42:0 54:0 56:0 100:0 125:0 126:0 \\
            2>>'$LOGFILE' || true
          ydotool type -- \"\$line \" 2>>'$LOGFILE' || true
        fi
      done
    " &

    echo "$!" > "$PIDFILE"
  '';

  meta = {
    description = "Toggle-style dictation using Moonshine's streaming ASR";
    platforms = [ "x86_64-linux" ];
    mainProgram = "moonshine-dictate";
  };
}
