{ pkgs, lib, ... }:

let
  # Digitalone1/EasyEffects-Presets - Loudness Equalizer presets
  digitalone1-presets = {
    LoudnessEqualizer = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Digitalone1/EasyEffects-Presets/master/LoudnessEqualizer.json";
      hash = "sha256-1vVMz+X+Zxldo7ull6FL3IGdvzuDO3nNosE3nPclvKw=";
    };
    LoudnessCrystalEqualizer = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Digitalone1/EasyEffects-Presets/master/LoudnessCrystalEqualizer.json";
      hash = "sha256-ErxIeM50rv6nwF9k+cSEuL3KiEVybbeARyazPd8BiXA=";
    };
  };

  # Bundy01/EasyEffects-Presets - Device-specific presets
  bundy01-presets = {
    Bose = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Bundy01/EasyEffects-Presets/main/Bose.json";
      hash = "sha256-uu8b4LWwqb15wghYJw3tnIuPvnp2WUid/FvVYHadQVw=";
    };
    Music = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Bundy01/EasyEffects-Presets/main/Music.json";
      hash = "sha256-ENlVTwiX8QfnGHcIwjIZlx/MusXHKgwdpYlYxqcULa8=";
    };
    Sony = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Bundy01/EasyEffects-Presets/main/Sony.json";
      hash = "sha256-KyI+buMeiv72i6VYeTobV9Z1I4VakpQffHU3mtwR99k=";
    };
    Video = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Bundy01/EasyEffects-Presets/main/Video.json";
      hash = "sha256-4onCl0zSgHzV21qCRb+ZbQJVg3vZok3RpohxikV6Kqw=";
    };
  };

  # Combine all presets
  allPresets = digitalone1-presets // bundy01-presets;
in
{
  # Install presets to ~/.local/share/easyeffects/output/
  xdg.dataFile = lib.mapAttrs' (name: src: {
    name = "easyeffects/output/${name}.json";
    value = { source = src; };
  }) allPresets;
}
