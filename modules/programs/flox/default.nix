{ config, inputs, lib, system, ... }:
let
  cfg = config.nixcfg.programs.flox;
in
{
  key = "nixcfg/programs/flox";

  options.nixcfg.programs.flox.enable = lib.mkEnableOption "Flox package manager";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.flox.packages.${system}.flox
      inputs.flox.packages.${system}.flox-cli
    ];

    environment.etc."flox.toml" = {
      text = ''
        disable_metrics = true
      '';

      mode = "0440";
    };
  };
}
