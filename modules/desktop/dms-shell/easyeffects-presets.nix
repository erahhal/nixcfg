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

  # JackHack96/EasyEffects-Presets - Popular preset collection
  jackhack96-presets = {
    AdvancedAutoGain = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Advanced%20Auto%20Gain.json";
      name = "Advanced-Auto-Gain.json";
      hash = "sha256-AXzy04ORMeg39H7ojkRtuumT0HU0nKLkU1SKmmD9zzQ=";
    };
    BassBoosted = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Bass%20Boosted.json";
      name = "Bass-Boosted.json";
      hash = "sha256-95tAsToEOza2ahION15oXwVjhToDyCfqSIuHQjmVV5s=";
    };
    BassEnhancingPerfectEQ = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Bass%20Enhancing%20+%20Perfect%20EQ.json";
      name = "Bass-Enhancing-Perfect-EQ.json";
      hash = "sha256-dQzjC/r++zAyWaaBmqyuB/09LsJQQftHRw/GzwLp18Q=";
    };
    Boosted = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Boosted.json";
      hash = "sha256-6/t+55AYuqYaxayJXJZhzAysV/x0QFWL4frehY9+s/E=";
    };
    LoudnessAutogain = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Loudness+Autogain.json";
      name = "Loudness-Autogain.json";
      hash = "sha256-Mypo7hd2w0vnVblxgeDzT2MEj8PeAk4wJ9whpA7yDlA=";
    };
    PerfectEQ = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Perfect%20EQ.json";
      name = "Perfect-EQ.json";
      hash = "sha256-LhXdj97iFgBouAbcxfabksSBJO/AouHPv1rcy2Zx9zI=";
    };
  };

  # RaduTek/EasyEffects-Presets - Laptop speaker presets
  radutek-laptop-presets = {
    ThinkPadZ13Gen1 = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/RaduTek/EasyEffects-Presets/main/ThinkPad%20Z13%20Gen%201.json";
      name = "ThinkPad-Z13-Gen1.json";
      hash = "sha256-prMddi+i7rF1dKtXu6+HdO9vg8f+B4zXjWKGUdvRJjA=";
    };
    SurfaceLaptop3 = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/RaduTek/EasyEffects-Presets/main/Surface%20Laptop%203.json";
      name = "Surface-Laptop-3.json";
      hash = "sha256-+NQBp+eQlOQx2xtl1fGvW1DdokAGwwiJOMqy4vFmj5U=";
    };
    AsusROGZephyrusG14 = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/RaduTek/EasyEffects-Presets/main/Asus%20ROG%20Zephyrus%20G14.json";
      name = "Asus-ROG-Zephyrus-G14.json";
      hash = "sha256-D6+f6PouxOtEJLeauXYsZ3YzP8iSFfxgjn1uM57f0Po=";
    };
  };

  # sebastian-de/easyeffects-thinkpad-unsuck - ThinkPad speaker improvement
  thinkpad-presets = {
    ThinkPadUnsuck = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/sebastian-de/easyeffects-thinkpad-unsuck/main/thinkpad-unsuck.json";
      hash = "sha256-iq21+xfoMiHN0BUsefSS4d3hXC6Cw1SmtUh9qnNh1W0=";
    };
  };

  # Combine all presets
  allPresets = digitalone1-presets
    // bundy01-presets
    // jackhack96-presets
    // radutek-laptop-presets
    // thinkpad-presets;

  # ==========================================================================
  # Impulse Response files (.irs) for Convolver effect
  # ==========================================================================

  # JackHack96 - Dolby Atmos impulse response
  dolbyAtmosIrs = {
    DolbyAtmosDefault = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/irs/Dolby%20ATMOS%20((128K%20MP3))%201.Default.irs";
      name = "Dolby-ATMOS-Default.irs";
      hash = "sha256-9Ft1HZLFTBiGRfh/wJiGZ9WstMtvdtX+u3lVY3JCVAM=";
    };
  };

  # shuhaowu/linux-thinkpad-speaker-improvements - ThinkPad P15 Dolby profiles
  # (closest match to P16)
  thinkpadP15Irs = {
    ThinkPadP15MusicBalanced = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shuhaowu/linux-thinkpad-speaker-improvements/main/ThinkPadP15Gen1/music_balanced.irs";
      hash = "sha256-pDqr3YWtKLIUkjGICgvtfWMbLEB92ABZPzBsCteZyGI=";
    };
    ThinkPadP15MoviesBalanced = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shuhaowu/linux-thinkpad-speaker-improvements/main/ThinkPadP15Gen1/movies_balanced.irs";
      hash = "sha256-darpMy2ccTWu+AHrOuunTVc1f8bVJ3NuI+NHLDKdswE=";
    };
    ThinkPadP15Voice = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shuhaowu/linux-thinkpad-speaker-improvements/main/ThinkPadP15Gen1/voice.irs";
      hash = "sha256-9G2AMXcZh/qu1AkBmwvVyNO+bYpc5VvlcHXeatrTOvY=";
    };
  };

  # shuhaowu/linux-thinkpad-speaker-improvements - ThinkPad T14 Gen 1 Dolby profiles
  # (T14 and P14s share similar speaker hardware, good option for P14s Gen 5)
  thinkpadT14Irs = {
    ThinkPadT14DolbyMusic = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shuhaowu/linux-thinkpad-speaker-improvements/main/ThinkPadT14Gen1/DolbyMusicBalanced.irs";
      hash = "sha256-X1DqZlNLX6pvHKJYuLzpz5e8DILtvplpO59uiKLSXlc=";
    };
    ThinkPadT14DolbyMovie = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shuhaowu/linux-thinkpad-speaker-improvements/main/ThinkPadT14Gen1/DolbyMovieBalanced.irs";
      hash = "sha256-lSlce7ZpKGyH2dvbU1XW/jE0AzcWl9x4Kz4QHVyDwOI=";
    };
    ThinkPadT14DolbyVoice = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shuhaowu/linux-thinkpad-speaker-improvements/main/ThinkPadT14Gen1/DolbyVoiceBalanced.irs";
      hash = "sha256-NFX3C92y5/og+QpGY6MIicjhFTSlRIuBM+CNtiNXo+c=";
    };
    ThinkPadT14DolbyGame = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shuhaowu/linux-thinkpad-speaker-improvements/main/ThinkPadT14Gen1/DolbyGameBalanced.irs";
      hash = "sha256-PBZWTvtH0N2UGoYFjE4Dk9NRKslqN5gfH82tYGXB83I=";
    };
  };

  # Combine all impulse responses
  allImpulseResponses = dolbyAtmosIrs // thinkpadP15Irs // thinkpadT14Irs;
in
{
  # Install presets to ~/.local/share/easyeffects/output/
  xdg.dataFile = (lib.mapAttrs' (name: src: {
    name = "easyeffects/output/${name}.json";
    value = { source = src; };
  }) allPresets) // (lib.mapAttrs' (name: src: {
    name = "easyeffects/irs/${name}.irs";
    value = { source = src; };
  }) allImpulseResponses);
}
