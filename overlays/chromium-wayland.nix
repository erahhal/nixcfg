{ userParams, ... }:
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

  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    home.activation.chromium = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Get to this setting by clicking the tab strip then checking "Use system title bar and borders"
      ${pkgs.gnused}/bin/sed -i 's/"custom_chrome_frame":true/"custom_chrome_frame":false/g' ~/.config/chromium/Default/Preferences
    '';
  };
}
