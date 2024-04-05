{ hostParams, ... }:
{
  programs.hyprlock = {
    enable = true;

    input-fields = [
      {
        outer_color = "rgb(24, 25, 38)";
        inner_color = "rgb(91, 96, 120)";
        font_color = "rgb(202, 211, 245)";
        halign = "center";
        valign = "center";
        size.width = 300;
        size.height = 40;
      }
    ];

    labels = [
      {
        text = "$TIME, $USER";
        color = "rgb(237, 135, 150)";
        font_family = "FiraCode";
        font_size = 72;
        halign = "center";
        valign = "center";
      }
    ];

    backgrounds = if builtins.hasAttr "wallpaper" hostParams then [
      {
        path = hostParams.wallpaper;
      }
    ] else [];
  };
}
