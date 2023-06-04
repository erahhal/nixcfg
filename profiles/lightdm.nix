{ pkgs, enabled, hostParams, userParams,... }:

{
  config = if hostParams.displayManager == "lightdm" then {
    services.xserver = {
      enable = true;
      dpi = hostParams.dpi;
      libinput.enable = true;
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
          enable = false;
          user = userParams.username;
        };
      };
    };
  } else {};
}
