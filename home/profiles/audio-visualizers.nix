{ pkgs, ... }:

let
  karmaviz = pkgs.callPackage ../../pkgs/karmaviz {};

  # projectM presets - En D pack (~50 curated presets by a single artist)
  projectm-presets = pkgs.fetchFromGitHub {
    owner = "projectM-visualizer";
    repo = "presets-en-d";
    rev = "fff71ea81223109f3558351667eef851f2781c96";
    hash = "sha256-aRxZRpa9uQkSgKm/m/Fkc+TWqfKdCYLgUYvZFh2Ugqk=";
  };

  # projectM textures - Milkdrop texture pack
  projectm-textures = pkgs.fetchFromGitHub {
    owner = "projectM-visualizer";
    repo = "presets-milkdrop-texture-pack";
    rev = "ff8edf2a8fa07e55ad562f1af97076526c484f7d";
    hash = "sha256-0PNCmaC+C5g2nFv4Oy7LtBfLj1NkyfhDBWSM17ilbpE=";
  };

  # Wrapper script for projectM with presets configured and automatic audio capture
  projectm-wrapper = pkgs.writeShellScriptBin "projectm" ''
    # Get the default audio output sink
    DEFAULT_SINK=$(${pkgs.pulseaudio}/bin/pactl get-default-sink 2>/dev/null)

    if [ -z "$DEFAULT_SINK" ]; then
      echo "Warning: Could not detect default audio sink, using default capture device"
      exec ${pkgs.projectm-sdl-cpp}/bin/projectMSDL \
        --presetPath="$HOME/.local/share/projectM/presets" \
        --texturePath="$HOME/.local/share/projectM/textures" \
        --shuffleEnabled=1 \
        --enableSplash=0 \
        "$@"
    fi

    # Create a pw-loopback to capture audio from the default sink's monitor
    # This creates a virtual capture device that projectMSDL can use
    ${pkgs.pipewire}/bin/pw-loopback \
      --capture-props="media.class=Audio/Sink node.name=projectm-capture node.description=projectM-Audio-Capture" \
      --playback-props="media.class=Audio/Source node.name=projectm-source node.description=projectM-Audio-Source" \
      &
    LOOPBACK_PID=$!

    # Ensure loopback is cleaned up on exit
    cleanup() {
      kill $LOOPBACK_PID 2>/dev/null
      wait $LOOPBACK_PID 2>/dev/null
    }
    trap cleanup EXIT INT TERM

    # Wait for loopback to initialize
    sleep 0.5

    # Link the default sink monitor to our loopback sink
    ${pkgs.pipewire}/bin/pw-link "$DEFAULT_SINK:monitor_FL" "projectm-capture:playback_FL" 2>/dev/null
    ${pkgs.pipewire}/bin/pw-link "$DEFAULT_SINK:monitor_FR" "projectm-capture:playback_FR" 2>/dev/null

    # Run projectMSDL with the loopback source as the audio device
    ${pkgs.projectm-sdl-cpp}/bin/projectMSDL \
      --presetPath="$HOME/.local/share/projectM/presets" \
      --texturePath="$HOME/.local/share/projectM/textures" \
      --shuffleEnabled=1 \
      --enableSplash=0 \
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

  # Install projectM presets and textures
  xdg.dataFile = {
    "projectM/presets" = {
      source = projectm-presets;
      recursive = true;
    };
    "projectM/textures" = {
      source = projectm-textures;
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
}
