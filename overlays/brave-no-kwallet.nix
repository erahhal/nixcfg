{ userParams, ... }:
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

  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    home.activation.brave = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Get to this setting by clicking the tab strip then checking "Use system title bar and borders"
      if [ -e ~/.config/BraveSoftware/Brave-Browser/Default/Preferences ]; then
        ${pkgs.gnused}/bin/sed -i 's/"custom_chrome_frame":true/"custom_chrome_frame":false/g' ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
      fi
    '';
  };
}
