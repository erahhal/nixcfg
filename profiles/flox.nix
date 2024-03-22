{ inputs, system, ... }:
{
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
}
