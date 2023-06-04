# DEPRECATED: Set NIXOS_OZONE_WL = 1 in session vars instead

{ pkgs, userParams, ... }:
let
  discord-exec-string = "${pkgs.discord}/bin/Discord --ignore-gpu-blocklist --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=VaapiVideoDecoder --use-gl=desktop --enable-gpu-rasterization --enable-zero-copy";
  discordWayland = pkgs.discord.overrideAttrs (oldAttrs: rec {
    desktopItem = oldAttrs.desktopItem.override {exec = discord-exec-string;};
    installPhase = builtins.replaceStrings ["${oldAttrs.desktopItem}"] ["${desktopItem}"] oldAttrs.installPhase;
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/discord \
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--ozone-platform=wayland"
    '';
  });
in
{
  home-manager.users.${userParams.username} = {
    home.packages = [
      discordWayland
    ];

    home.file.".config/discord/settings.json" = {
      text = builtins.toJSON {
        "BACKGROUND_COLOR" = "#202225";
        "IS_MAXIMIZED" = true;
        "IS_MINIMIZED" = false;
        # Discord likes to break old versions. Don't do that
        "SKIP_HOST_UPDATE" = true;
      };
    };
  };
}
