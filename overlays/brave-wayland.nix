{ ... }:
let braveWayland = final: prev: {
  brave = prev.brave.override {
    commandLineArgs = [
      "--ozone-platform-hint=auto"
    ];
  };
};
in
{
  nixpkgs.overlays = [ braveWayland ];
}
