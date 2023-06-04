{ ... }:
let chromiumWayland = final: prev: {
  chromium = prev.unstable.chromium.override {
    commandLineArgs = [
      "--ozone-platform-hint=auto"
    ];
  };
};
in
{
  nixpkgs.overlays = [ chromiumWayland ];
}
