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

  # Wrapper script for projectM with presets configured
  projectm-wrapper = pkgs.writeShellScriptBin "projectm" ''
    exec ${pkgs.projectm-sdl-cpp}/bin/projectMSDL \
      --presetPath="$HOME/.local/share/projectM/presets" \
      --texturePath="$HOME/.local/share/projectM/textures" \
      --shuffleEnabled=1 \
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
