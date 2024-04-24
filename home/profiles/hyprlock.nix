{ hostParams, ... }:
{
  programs.hyprlock = {
    enable = true;

    general = {
      no_fade_in = true;
      no_fade_out = true;
    };

    input-fields = [
      {
        outer_color = "rgb(24, 25, 38)";
        inner_color = "rgb(91, 96, 120)";
        font_color = "rgb(202, 211, 245)";
        halign = "center";
        valign = "center";
        size.width = 360;
        size.height = 50;
      }
    ];

    labels = [
      {
        # text = "$TIME, $USER";
        text = ''cmd[update:1000] echo "<span foreground='##ff2222'>$(date)</span>"'';
        color = "rgb(237, 135, 150)";
        font_family = "FiraCode";
        font_size = 72;
        halign = "center";
        valign = "center";
      }
    ];

    backgrounds = if builtins.hasAttr "wallpaper" hostParams then [
      {
        # blank means "all monitors"
        monitor = "";
        # Only PNG supported for now
        path = hostParams.wallpaper;
      }
    ] else [];
  };
}
