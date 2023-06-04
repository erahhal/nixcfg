{ inputs, pkgs, system, ... }:
{
  environment.systemPackages = with pkgs; [
    inputs.dcc.packages."${system}".dcc
  ];
}
