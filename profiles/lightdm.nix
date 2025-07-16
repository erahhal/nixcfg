{ config, lib, pkgs, userParams,... }:

{
  config = lib.mkIf (config.hostParams.desktop.displayManager == "lightdm") {
    services.libinput.enable = true;

    services.xserver = {
      enable = true;
      dpi = config.hostParams.desktop.dpi;
      displayManager = {
        defaultSession = config.hostParams.desktop.defaultSession;
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
          enable = config.hostParams.desktop.autoLogin;
          user = userParams.username;
        };
      };
    };
  };
}
