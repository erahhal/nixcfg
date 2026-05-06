{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "niri-focused-booster";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "1Naim";
    repo = "niri-focused-booster";
    rev = version;
    hash = "sha256-a+aiiKLxYCxqDwHhVnzByn/SA3Q7c/Ok/Z+31MESCkw=";
  };

  cargoHash = "sha256-b5TkOaI2/pSX2uugkViKy13tUpptOHAPY6jR+RdaNUo=";

  meta = {
    description = "Boosts dmem cgroup VRAM protection for the focused window in Niri";
    homepage = "https://github.com/1Naim/niri-focused-booster";
    license = lib.licenses.gpl3Only;
    mainProgram = "niri-focused-booster";
    platforms = lib.platforms.linux;
  };
}
