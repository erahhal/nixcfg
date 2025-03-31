{ pkgs, hostParams, userParams,... }:

{
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
        enable = false;
        user = userParams.username;
      };
    };
  };
}
