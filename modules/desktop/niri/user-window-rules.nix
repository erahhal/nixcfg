{ config, ... }:
let
  userParams = config.hostParams.user;
in
{
  home-manager.users.${userParams.username} = {
    programs.niri.settings.window-rules = [
      { matches = [{ app-id = "org.chromium.Chromium$"; }]; open-on-workspace = "one"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "chromium-browser"; }]; open-on-workspace = "one"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "kitty$"; }]; open-on-workspace = "two"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "foot$"; }]; open-on-workspace = "two"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "Slack$"; }]; open-on-workspace = "three"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "spotify$"; }]; open-on-workspace = "four"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "Spotify$"; }]; open-on-workspace = "four"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "brave-browser$"; }]; open-on-workspace = "four"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "firefox$"; }]; open-on-workspace = "five"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "signal$"; }]; open-on-workspace = "six"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "Signal$"; }]; open-on-workspace = "six"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "org.telegram.desktop$"; }]; open-on-workspace = "six"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "wechat$"; }]; open-on-workspace = "six"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "discord$"; }]; open-on-workspace = "seven"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "vesktop$"; }]; open-on-workspace = "seven"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "Element$"; }]; open-on-workspace = "seven"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "^electron$"; title = "^Element"; }]; open-on-workspace = "seven"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "zoom$"; }]; open-on-workspace = "eight"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "@joplin/app-desktop$"; }]; open-on-workspace = "nine"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "Joplin$"; }]; open-on-workspace = "nine"; default-column-width = { proportion = 1.0; }; }
      { matches = [{ app-id = "joplin$"; }]; open-on-workspace = "nine"; default-column-width = { proportion = 1.0; }; }
      {
        matches = [
          { app-id = "steam"; }
          { app-id = "com.valvesoftware.Steam"; }
        ];
        open-maximized = true;
        open-focused = true;
        open-on-workspace = "ten";
        default-column-width = { proportion = 1.0; };
      }
    ];
  };
}
