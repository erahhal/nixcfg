{ inputs, lib, pkgs, userParams, ... }:
let
  hyprland = pkgs.hyprland;
  # hyprland = pkgs.hyprland-patched;
  # hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  ## @TODO: Should really use %h from systemd and pass it in here to
  ##        get user home directory
  toggle-theme-script = pkgs.writeShellScriptBin "toggle-theme-script" ''
    set +e

    HOME=/home/${userParams.username}
    SYSTEM_THEME=$(cat $HOME/.system-theme)
    if [ "$SYSTEM_THEME" == "light-mode" ]; then
      GENERATION=$(home-manager generations | head -2 | tail -1 | rg -o '/[^ ]*')
    else
      GENERATION=$(home-manager generations | head -1 | rg -o '/[^ ]*')/specialisation/light-mode
    fi
    "$GENERATION"/activate

    if pidof sway > /dev/null; then
      pkill waybar
      tmux source-file $HOME/.tmux.conf
      systemctl --user restart swaynotificationcenter
      swaymsg reload
    elif ${pkgs.procps}/bin/pidof Hyprland > /dev/null; then
      echo ">> killing waybar"
      pkill waybar
      echo ">> reloading tmux"
      tmux source-file $HOME/.tmux.conf
      echo ">> restarting SwayNC"
      systemctl --user restart swaynotificationcenter
      echo ">> reloading hyprland"
      ${hyprland}/bin/hyprctl reload
      sleep 1
      echo ">> launching waybar"
      ## This only seems to launch if logging at trace level and running in foreground
      waybar -l trace
    fi
  '';
  runtime-paths = lib.makeBinPath [
    pkgs.coreutils
    pkgs.home-manager
    pkgs.procps
    pkgs.ripgrep
    pkgs.sway
    pkgs.systemd
    pkgs.tmux
    hyprland
    pkgs.waybar
    # inputs.waybar.packages.${pkgs.system}.waybar
  ];
  toggle-theme = pkgs.stdenv.mkDerivation {
    name = "toggle-theme";

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    installPhase = ''
      install -Dm755 ${toggle-theme-script}/bin/toggle-theme-script $out/bin/toggle-theme

      wrapProgram $out/bin/toggle-theme \
        --suffix PATH : ${runtime-paths}
    '';
  };
in
{
  # This theme switching mechanism heavily inspired by the following post:
  # https://discourse.nixos.org/t/home-manager-toggle-between-themes/32907

  # @TODOs
  # - Get Slack to change themes with system
  # - Automatically restart Discord if running, as it doesn't kick in without restart
  # - Fix tmux config split
  # - Fix other config splits (swaync, launcher.rasi, waybar)

  imports = [
    ./system-theme-dark.nix
  ];

  specialisation = {
    light-mode.configuration = {
      imports = [
        ./system-theme-light.nix
      ];
    };
  };

  systemd.user.services.toggle-theme = {
    Unit = {
      Description = "Theme toggler";
    };
    Service = {
      Restart = "no";
      ExecStart = "${toggle-theme}/bin/toggle-theme";
    };
  };

  ## base16 guide
  # base00 - Default Background
  # base01 - Lighter Background (Used for status bars, line number and folding marks)
  # base02 - Selection Background
  # base03 - Comments, Invisibles, Line Highlightingk
  # base04 - Dark Foreground (Used for status bars)
  # base05 - Default Foreground, Caret, Delimiters, Operators
  # base06 - Light Foreground (Not often used)
  # base07 - Light Background (Not often used)
  # base08 - Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
  # base09 - Integers, Boolean, Constants, XML Attributes, Markup Link Url
  # base0A - Classes, Markup Bold, Search Text Background
  # base0B - Strings, Inherited Class, Markup Code, Diff Inserted
  # base0C - Support, Regular Expressions, Escape Characters, Markup Quotes
  # base0D - Functions, Methods, Attribute IDs, Headings
  # base0E - Keywords, Storage, Selector, Markup Italic, Diff Changed
  # base0F - Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
}
