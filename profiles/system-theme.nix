{ ... }:
{
  # @TODO: move this into flake.nix,
  # loading configuration.nix with an argument as
  # to which theme is used
  specialisation = {
    dark-mode.configuration = {
      imports = [
        ./system-theme-dark.nix
      ];
    };
    light-mode.configuration = {
      imports = [
        ./system-theme-light.nix
      ];
    };
  };
}
