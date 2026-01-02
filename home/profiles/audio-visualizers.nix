# projectM Keybindings:
#   ESC     - Toggle UI
#   F1      - Show help
#   F3      - Toggle preset name
#   F4      - Toggle rendering stats
#   F5      - Show FPS
#   m       - Open preset menu/browser
#   f       - Toggle fullscreen
#   l       - Lock/unlock current preset
#   y       - Toggle shuffle mode
#   n       - Next preset
#   p       - Previous preset
#   r       - Random preset
#   Up/Down - Adjust beat sensitivity
#   Ctrl+I  - Next audio input device
#   Ctrl+Q  - Quit

{ pkgs, ... }:

let
  karmaviz = pkgs.callPackage ../../pkgs/karmaviz {};

  # All available projectM preset packs
  presetPacks = {
    # ~50 curated presets by En D
    en-d = pkgs.fetchFromGitHub {
      owner = "projectM-visualizer";
      repo = "presets-en-d";
      rev = "fff71ea81223109f3558351667eef851f2781c96";
      hash = "sha256-aRxZRpa9uQkSgKm/m/Fkc+TWqfKdCYLgUYvZFh2Ugqk=";
    };
    # ~9,795 best-of-best curated presets
    cream-of-the-crop = pkgs.fetchFromGitHub {
      owner = "projectM-visualizer";
      repo = "presets-cream-of-the-crop";
      rev = "0180df21f5e0bd39b9060cc5de420ed2f1f9e509";
      hash = "sha256-4ZyrXmiLR8hyzad9qPjOiDaVEEpPDR+nBr2uTrbRxLw=";
    };
    # ~4,200 legacy projectM presets
    classic = pkgs.fetchFromGitHub {
      owner = "projectM-visualizer";
      repo = "presets-projectm-classic";
      rev = "14a6244a7d32eb7e114e1a92d1cb93358cdcc54a";
      hash = "sha256-BfhTC6b9oA3+nQES1pQ9WAUA13Mg4OJJq9huSQo29pM=";
    };
    # Original Milkdrop release presets
    milkdrop-original = pkgs.fetchFromGitHub {
      owner = "projectM-visualizer";
      repo = "presets-milkdrop-original";
      rev = "e03b83e3338d8f1ed6cbcf908c719f249ef24288";
      hash = "sha256-obuXgHg0uZjdsnkeIplsAcELQ3/zbpCSVUaP6LLUfvw=";
    };
  };

  # Preset packs to enable (available: en-d, cream-of-the-crop, classic, milkdrop-original)
  enabledPresetPacks = [
    "en-d"
    "cream-of-the-crop"
    "classic"
    "milkdrop-original"
  ];

  # Visualization timing settings
  presetDuration = 30;        # Seconds before auto-switching presets (default: 30)
  transitionDuration = 3;     # Seconds for crossfade between presets (default: 3)
  hardCutsEnabled = true;     # Allow beat-triggered preset changes
  hardCutDuration = 20;       # Minimum seconds between hard cuts (default: 20)
  hardCutSensitivity = 1.0;   # Beat detection sensitivity 0.0-5.0 (default: 1.0)
  beatSensitivity = 1.0;      # Overall beat sensitivity 0.0-2.0 (default: 1.0)

  # Combine all enabled preset packs into one directory
  combinedPresets = pkgs.symlinkJoin {
    name = "projectm-presets-combined";
    paths = map (name: presetPacks.${name}) enabledPresetPacks;
  };

  # projectM textures - Milkdrop texture pack
  projectm-textures = pkgs.fetchFromGitHub {
    owner = "projectM-visualizer";
    repo = "presets-milkdrop-texture-pack";
    rev = "ff8edf2a8fa07e55ad562f1af97076526c484f7d";
    hash = "sha256-0PNCmaC+C5g2nFv4Oy7LtBfLj1NkyfhDBWSM17ilbpE=";
  };

  # Wrapper script for projectM (uses persistent loopback from systemd service)
  projectm-wrapper = pkgs.writeShellScriptBin "projectm" ''
    # Get the default audio output sink and link to persistent loopback
    DEFAULT_SINK=$(${pkgs.pulseaudio}/bin/pactl get-default-sink 2>/dev/null)

    if [ -n "$DEFAULT_SINK" ]; then
      # Link the default sink monitor to the persistent loopback
      ${pkgs.pipewire}/bin/pw-link "$DEFAULT_SINK:monitor_FL" "projectm-capture:playback_FL" 2>/dev/null
      ${pkgs.pipewire}/bin/pw-link "$DEFAULT_SINK:monitor_FR" "projectm-capture:playback_FR" 2>/dev/null
    fi

    # Run projectMSDL with the loopback source as the audio device
    # Note: custom-presets in ~/.local/share/projectM/custom-presets/ not yet integrated
    exec ${pkgs.projectm-sdl-cpp}/bin/projectMSDL \
      --presetPath="${combinedPresets}" \
      --texturePath="${projectm-textures}/textures" \
      --shuffleEnabled=1 \
      --enableSplash=0 \
      --presetDuration=${toString presetDuration} \
      --transitionDuration=${toString transitionDuration} \
      --hardCutsEnabled=${if hardCutsEnabled then "1" else "0"} \
      --hardCutDuration=${toString hardCutDuration} \
      --hardCutSensitivity=${toString hardCutSensitivity} \
      --beatSensitivity=${toString beatSensitivity} \
      --audioDevice="projectM-Audio-Source" \
      "$@"
  '';
in
{
  home.packages = [
    # projectM - Milkdrop-compatible music visualizer (use 'projectm' wrapper)
    projectm-wrapper

    # Cavalier - GTK4 audio visualizer based on CAVA
    pkgs.cavalier

    # CAVA - Console-based audio visualizer (used by Cavalier)
    pkgs.cava

    # KarmaViz - GPU-accelerated audio visualizer
    karmaviz
  ];

  # Install projectM presets and textures (single directory symlinks, not recursive)
  # Custom presets directory is recursive so you can add your own .milk files
  xdg.dataFile = {
    "projectM/presets".source = combinedPresets;
    "projectM/textures".source = "${projectm-textures}/textures";
    "projectM/custom-presets" = {
      source = pkgs.runCommand "projectm-custom-presets" {} "mkdir -p $out";
      recursive = true;
    };
  };

  # CAVA configuration for console visualizer and Cavalier backend
  xdg.configFile."cava/config".text = ''
    [general]
    framerate = 60
    autosens = 1
    sensitivity = 100
    bars = 0
    bar_width = 2
    bar_spacing = 1

    [input]
    method = pipewire
    source = auto

    [output]
    method = ncurses
    channels = stereo
    mono_option = average

    [color]
    gradient = 1
    gradient_count = 6
    gradient_color_1 = '#59cc33'
    gradient_color_2 = '#80cc33'
    gradient_color_3 = '#cccc33'
    gradient_color_4 = '#ccad33'
    gradient_color_5 = '#cc8033'
    gradient_color_6 = '#cc3333'

    [smoothing]
    integral = 77
    monstercat = 0
    waves = 0
    gravity = 100
    noise_reduction = 77
  '';

  # Persistent PipeWire loopback for projectM audio capture
  # This runs continuously so music players don't see sinks appear/disappear
  systemd.user.services.projectm-audio-capture = {
    Unit = {
      Description = "PipeWire loopback for projectM audio visualization";
      PartOf = [ "graphical-session.target" ];
      After = [ "pipewire.service" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.pipewire}/bin/pw-loopback --capture-props=\"media.class=Audio/Sink node.name=projectm-capture node.description=projectM-Audio-Capture node.passive=true priority.session=0\" --playback-props=\"media.class=Audio/Source node.name=projectm-source node.description=projectM-Audio-Source node.passive=true\"";
    };
  };
}
