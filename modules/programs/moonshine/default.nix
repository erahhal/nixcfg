{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.moonshine;
  userParams = config.hostParams.user;

  # The library itself (importable as moonshine_voice).
  moonshine-voice = pkgs.python3.pkgs.callPackage ../../../pkgs/moonshine-voice { };

  # A Python env that can be called directly (e.g. `moonshine-mic --language en`).
  moonshinePython = pkgs.python3.withPackages (ps: [
    (ps.callPackage ../../../pkgs/moonshine-voice { })
  ]);

  # `moonshine-mic` is just a thin alias for `python -m moonshine_voice.mic_transcriber`
  # so it can be launched without remembering the module path.
  moonshine-mic = pkgs.writeShellApplication {
    name = "moonshine-mic";
    runtimeInputs = [ moonshinePython ];
    text = ''exec python -m moonshine_voice.mic_transcriber "$@"'';
  };

  # Toggle-style dictation: first press starts, second press stops.
  moonshine-dictate = pkgs.callPackage ../../../pkgs/moonshine-dictate {
    inherit (cfg) modelArch language;
  };
in
{
  key = "nixcfg/programs/moonshine";

  options.nixcfg.programs.moonshine = {
    enable = lib.mkEnableOption ''
      Moonshine Voice -- low-latency streaming on-device ASR from Moonshine
      AI (https://github.com/moonshine-ai/moonshine). Installs the Python
      library plus two helper commands:
        * moonshine-mic   -- just runs the mic transcriber, prints to stdout
        * moonshine-dictate -- toggle: start/stop dictation, paste via ydotool
    '';

    modelArch = lib.mkOption {
      type = lib.types.enum [ 0 1 2 3 4 5 ];
      default = 2;
      description = ''
        Model architecture for moonshine-dictate (see ModelArch enum):
          0 = TINY             (batch, ~44 MB, shipped with the wheel -- offline on first run)
          1 = BASE             (batch, ~60 MB)
          2 = TINY_STREAMING   (streaming, ~50 MB, DEFAULT -- best latency/size tradeoff)
          3 = BASE_STREAMING   (streaming)
          4 = SMALL_STREAMING  (streaming, higher accuracy)
          5 = MEDIUM_STREAMING (streaming, best accuracy, ~400 MB)
        All non-zero variants auto-download on first run into
        ~/.cache/moonshine-voice/.
      '';
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
      example = "es";
      description = ''
        Language code passed to moonshine-dictate. Streaming variants are
        English-only today; non-English models use the BASE arch regardless.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      moonshinePython
      moonshine-mic
      moonshine-dictate
    ];

    # moonshine-dictate types via ydotool, which needs the system daemon and
    # the user in the ydotool group.
    programs.ydotool.enable = true;
    users.users.${userParams.username}.extraGroups = [ "ydotool" ];
  };
}
