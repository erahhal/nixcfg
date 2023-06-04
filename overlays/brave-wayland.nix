{ ... }:
let braveWayland = final: prev: {
  brave = prev.trunk.brave.override {
    commandLineArgs = [
      "--ozone-platform-hint=auto"
    ];
  };
};
in
{
  nixpkgs.overlays = [ braveWayland ];
}
