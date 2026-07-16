{ config, inputs, lib, pkgs, system, ... }:
let
  cfg = config.nixcfg.programs.switchyard;
  username = config.hostParams.user.username;

  switchyardConfig = {
    favorite_browser = cfg.favoriteBrowser;
    prompt_on_click = false;
    check_default_browser = false;
    rules = cfg.rules;
  };

  tomlFormat = pkgs.formats.toml { };
in
{
  key = "nixcfg/programs/switchyard";

  options.nixcfg.programs.switchyard = {
    enable = lib.mkEnableOption "Switchyard rules-based browser launcher";

    favoriteBrowser = lib.mkOption {
      type = lib.types.str;
      default = "firefox.desktop";
      description = "Desktop file ID of the fallback browser used when no rule matches.";
    };

    rules = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [];
      description = ''
        Switchyard routing rules. Lists merge across module declarations, so generic
        desktop defaults can live in the desktop module and hosts add their own.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.switchyard.packages.${system}.switchyard
    ];

    home-manager.users.${username}.xdg.configFile."switchyard/config.toml".source =
      tomlFormat.generate "switchyard-config.toml" switchyardConfig;
  };
}
