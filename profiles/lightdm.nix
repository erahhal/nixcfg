{ config, lib, pkgs, hostParams, userParams,... }:

{
  config = lib.mkIf (config.hostParams.desktop.displayManager == "lightdm") {
    services.libinput.enable = true;

    services.xserver = {
      enable = true;
      dpi = hostParams.dpi;
      displayManager = {
        defaultSession = hostParams.defaultSession;
        lightdm = {
          enable = true;
          greeters = {
            gtk = {
              enable = true;
              cursorTheme = {
                package = pkgs.gnome3.defaultIconTheme;
                name = "Adwaita";
                # @TODO: make a variable
                size = 36;
              };
            };
          };
        };

        autoLogin = {
          enable =hostParams.autoLogin;
          user = userParams.username;
        };
      };
    };
  };
}
