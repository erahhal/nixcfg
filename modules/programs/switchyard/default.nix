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
      # Upstream's buildPhase writes the Go binary to ./switchyard in the
      # source dir, but buildGoModule's installPhase only installs
      # $GOPATH/bin/*, so $out/bin ends up empty. Build into $GOPATH/bin
      # directly. Tracked at: https://github.com/alyraffauf/switchyard
      (inputs.switchyard.packages.${system}.switchyard.overrideAttrs (_: {
        buildPhase = ''
          runHook preBuild
          mkdir -p $GOPATH/bin
          go build -mod=vendor -trimpath -ldflags="-s -w" \
            -o $GOPATH/bin/switchyard ./src
          runHook postBuild
        '';
      }))
    ];

    home-manager.users.${username}.xdg.configFile."switchyard/config.toml".source =
      tomlFormat.generate "switchyard-config.toml" switchyardConfig;
  };
}
