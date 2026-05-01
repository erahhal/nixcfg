{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.whisper-dictation;
  userParams = config.hostParams.user;

  # whisper-cpp from nixpkgs is CPU-only by default. On an RTX 4090 Laptop
  # with 4 threads that means ~3x-realtime transcription for
  # large-v3-turbo-q5_0 -- a 6-second clip takes ~18 s, which is the delay
  # the user was hitting. Vulkan support (opt-in flag in the nixpkgs
  # derivation) offloads the compute to any GPU the driver exposes, taking
  # that same clip to ~0.5-1 s. We pick Vulkan over CUDA because:
  #   * same built binary works on both the NVIDIA laptop and the AMD one;
  #   * no redistributable EULA / long CUDA rebuild;
  #   * whisper.cpp's Vulkan backend is mature as of 1.6+.
  whisperCpp = pkgs.whisper-cpp.override {
    vulkanSupport = cfg.vulkanSupport;
  };

  modelHashes = import ./models.nix;

  fetchModel = name:
    let
      sha256 = modelHashes.${name} or (throw
        "whisper-dictation: unknown model '${name}'. Known models: ${
          toString (lib.attrNames modelHashes)
        }. To add a new model, update modules/programs/whisper-dictation/models.nix.");
    in
    pkgs.fetchurl {
      name = "ggml-${name}.bin";
      url  = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${name}.bin";
      inherit sha256;
      curlOptsList = [ "--retry" "3" "--retry-delay" "5" ];
    };

  # The "primary" model is the first entry in `models`; it's what the toggle
  # script uses. Any additional entries are fetched into /nix/store so they're
  # available for manual `whisper-cli -m ...` invocations.
  defaultModelName = lib.head cfg.models;
  modelDrvs        = lib.genAttrs cfg.models fetchModel;
  defaultModel     = modelDrvs.${defaultModelName};

  # Toggle-style dictation, matching the shape of nerd-dictation-toggle and
  # moonshine-dictate:
  #
  #   1st invocation: start ffmpeg recording to a WAV in $XDG_RUNTIME_DIR,
  #                   save its PID, show a "recording" notification.
  #   2nd invocation: SIGINT ffmpeg (flushes a valid RIFF header), run
  #                   whisper-cli on the WAV, pipe the text through
  #                   `ydotool type` into whatever window is focused.
  #
  # Whisper is batch-at-stop -- the transcription runs only after you finish
  # speaking -- but the full large-v3-turbo-q5_0 model is fast enough (~0.5x
  # realtime on a modern laptop CPU) that the delay between "stop" and "text
  # appears" is a second or two for typical-length dictations.
  whisper-dictate = pkgs.writeShellApplication {
    name = "whisper-dictate";
    runtimeInputs = [
      whisperCpp     # whisper-cli (Vulkan-accelerated if cfg.vulkanSupport)
    ] ++ (with pkgs; [
      # ffmpeg-headless is missing --enable-libpulse, so `-f pulse` fails at
      # runtime with "Unknown input format: 'pulse'". The full ffmpeg build
      # has the PulseAudio demuxer.
      ffmpeg
      ydotool
      libnotify
      coreutils      # sleep, cat, rm
      gnused         # sed
    ]);
    text = ''
      # whisper-dictate -- toggle-style push-to-talk dictation using whisper.cpp.
      #
      # Files:
      #   $XDG_RUNTIME_DIR/whisper-dictate.pid  -- ffmpeg PID while recording
      #   $XDG_RUNTIME_DIR/whisper-dictate.wav  -- captured audio
      #   $XDG_RUNTIME_DIR/whisper-dictate.log  -- diagnostic log

      set +e

      RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      PIDFILE="$RUNTIME_DIR/whisper-dictate.pid"
      WAVFILE="$RUNTIME_DIR/whisper-dictate.wav"
      LOGFILE="$RUNTIME_DIR/whisper-dictate.log"

      MODEL=${defaultModel}
      LANGUAGE=${lib.escapeShellArg cfg.language}
      THREADS=${toString cfg.threads}

      if [ -f "$PIDFILE" ]; then
        # ------ STOP + TRANSCRIBE path ------
        pid="$(cat "$PIDFILE")"
        rm -f "$PIDFILE"

        # SIGINT lets ffmpeg flush a valid WAV trailer; SIGKILL would leave
        # the header's RIFF size fields unpatched.
        if [ -n "$pid" ] && kill -INT "$pid" 2>/dev/null; then
          # Wait up to ~2 s for ffmpeg to exit cleanly.
          for _ in $(seq 1 40); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.05
          done
        fi

        notify-send -t 2000 -a whisper-dictate \
          "whisper-dictate" "▶ transcribing..." 2>/dev/null || true

        if [ ! -s "$WAVFILE" ]; then
          notify-send -t 2000 -a whisper-dictate \
            "whisper-dictate" "⚠ no audio captured" 2>/dev/null || true
          exit 1
        fi

        # -nt (no timestamps) + -np (no prints) leaves only the transcribed
        # text on stdout. Collapse newlines into spaces and trim.
        # NOTE: no `-ngl` flag. whisper.cpp is not llama.cpp -- it has no
        # layer-count switch. When whisper-cpp is built with
        # vulkanSupport=true (see the `vulkanSupport` option and the
        # whisper-cpp override below) the Vulkan backend is loaded at
        # runtime automatically and uses the first discrete GPU it finds;
        # with vulkanSupport=false, whisper-cli runs on CPU. Passing -ngl
        # to whisper-cli makes it error with "unknown argument" and print
        # its entire help text to stdout, which this script would then
        # dutifully type at the user. We don't want that.
        text=$(
          whisper-cli \
            -m "$MODEL" \
            -f "$WAVFILE" \
            -l "$LANGUAGE" \
            -t "$THREADS" \
            -nt -np \
            2>>"$LOGFILE" \
            | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
            | tr '\n' ' ' \
            | sed 's/  */ /g; s/^ //; s/ $//'
        )

        rm -f "$WAVFILE"

        if [ -z "$text" ]; then
          notify-send -t 2000 -a whisper-dictate \
            "whisper-dictate" "⚠ no speech detected" 2>/dev/null || true
          exit 0
        fi

        # Release any modifier the user might still be holding from the
        # hotkey (Ctrl/Shift/Alt/Super, both sides). Without this, uinput's
        # view of the keyboard can have Super depressed while ydotool types,
        # so each character reaches niri as Super+<letter> and triggers
        # window-management binds instead of reaching the focused app.
        # Keycodes: 29=LCtrl 97=RCtrl 42=LShift 54=RShift 56=LAlt 100=RAlt
        #           125=LSuper 126=RSuper
        ydotool key 29:0 97:0 42:0 54:0 56:0 100:0 125:0 126:0 \
          2>>"$LOGFILE" || true

        # Type with trailing space so consecutive dictations don't run together.
        ydotool type -- "$text " 2>>"$LOGFILE"

        notify-send -t 1500 -a whisper-dictate \
          "whisper-dictate" "✓ typed $(printf %s "$text" | wc -c) chars" 2>/dev/null || true
        exit 0
      fi

      # ------ START path ------
      : > "$LOGFILE"

      notify-send -t 1500 -a whisper-dictate \
        "whisper-dictate" "● recording..." 2>/dev/null || true

      # 16 kHz mono = whisper.cpp's native sample rate; no internal resample
      # step needed at transcription time. Pulse backend works on pipewire
      # systems too via pipewire-pulse shim.
      ffmpeg \
        -hide_banner -loglevel warning \
        -f pulse -i default \
        -ac 1 -ar 16000 \
        -y "$WAVFILE" \
        2>>"$LOGFILE" &

      echo "$!" > "$PIDFILE"
    '';
  };
in
{
  key = "nixcfg/programs/whisper-dictation";

  options.nixcfg.programs.whisper-dictation = {
    enable = lib.mkEnableOption ''
      whisper-dictate -- toggle-style speech-to-text using whisper.cpp.
      First keypress starts recording, second keypress stops and transcribes,
      typing the result via ydotool into whatever window is focused. See
      https://github.com/ggerganov/whisper.cpp for the upstream engine.
    '';

    models = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames modelHashes));
      default = [ "large-v3-turbo-q5_0" ];
      example = [ "large-v3-turbo-q5_0" "base.en" ];
      description = ''
        Whisper.cpp ggml models to fetch into /nix/store (SHA256-verified).
        The first entry is the model `whisper-dictate` uses for every
        invocation; additional entries are pulled in so you can pass them
        to `whisper-cli -m ...` manually. Update
        modules/programs/whisper-dictation/models.nix to add new entries.
      '';
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
      example = "auto";
      description = ''
        Language code passed to whisper-cli. "auto" enables detection at the
        cost of ~1 s extra latency on every dictation.
      '';
    };

    threads = lib.mkOption {
      type = lib.types.int;
      default = 16;
      description = ''
        whisper-cli thread count. Higher values speed up transcription on
        large models; diminishing returns past physical core count. For a
        GPU build (vulkanSupport = true) this governs only the pre/post
        processing on CPU, so 4-8 is usually enough.
      '';
    };

    vulkanSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Build whisper-cpp with its Vulkan backend so inference runs on the
        GPU. Drastically faster than CPU-only (tens of seconds \u2192 under a
        second on a modern discrete GPU) and works across both NVIDIA and
        AMD hardware without a driver-specific rebuild.
        Set false if you don't have a Vulkan-capable ICD installed or want
        to avoid the one-time whisper-cpp rebuild.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      whisper-dictate
      whisperCpp   # whisper-cli on PATH for ad-hoc use (same Vulkan build)
    ];

    # whisper-dictate types via ydotool, which needs the ydotoold system
    # daemon and "ydotool" group membership.
    programs.ydotool.enable = true;
    users.users.${userParams.username}.extraGroups = [ "ydotool" ];

    # Surface every configured model at a stable path on disk so you can pass
    # e.g. ~/.local/share/whisper/models/ggml-base.en.bin to whisper-cli
    # without remembering the /nix/store hash. Primarily useful when calling
    # whisper-cli manually; the toggle script hard-codes the store path of
    # the primary model.
    home-manager.users.${userParams.username} = { lib, ... }: {
      home.file = lib.mapAttrs' (name: drv:
        lib.nameValuePair ".local/share/whisper/models/ggml-${name}.bin" {
          source = drv;
        }
      ) modelDrvs;
    };
  };
}
