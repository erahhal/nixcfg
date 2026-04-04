{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.steam-loader;

  steam-loader = pkgs.python3Packages.buildPythonApplication {
    pname = "steam-loader";
    version = "1.0.0";
    format = "other";

    src = ./src;

    nativeBuildInputs = [ pkgs.wrapGAppsHook3 ];

    buildInputs = [
      pkgs.gtk4
      pkgs.libadwaita
      pkgs.gtk4-layer-shell
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      pygobject3
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp steam-loader.py $out/bin/steam-loader
      chmod +x $out/bin/steam-loader
    '';

    # Ensure GTK4 and layer shell libraries are found
    preFixup = ''
      gappsWrapperArgs+=(
        --prefix GI_TYPELIB_PATH : "${pkgs.gtk4}/lib/girepository-1.0"
        --prefix GI_TYPELIB_PATH : "${pkgs.libadwaita}/lib/girepository-1.0"
        --prefix GI_TYPELIB_PATH : "${pkgs.gtk4-layer-shell}/lib/girepository-1.0"
      )
    '';
  };

in {
  options.programs.steam-loader = {
    enable = mkEnableOption "Steam Big Picture loading screen for Niri";

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to automatically start the loader when Niri starts";
    };

    package = mkOption {
      type = types.package;
      default = steam-loader;
      description = "The steam-loader package to use";
    };
  };

  config = mkIf cfg.enable {
    # Ensure required packages are available
    environment.systemPackages = [
      cfg.package
      pkgs.steam
    ];

    # If using home-manager for niri config, you'd add this to spawn-at-startup
    # Otherwise, provide instructions for manual configuration
  };
}
