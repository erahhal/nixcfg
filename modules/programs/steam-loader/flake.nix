{
  description = "Steam Big Picture loading screen for Niri/Wayland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        steam-loader = let
          # Collect all the GI typelib dependencies
          giTypelibs = [
            pkgs.gobject-introspection
            pkgs.gtk4
            pkgs.libadwaita
            pkgs.gtk4-layer-shell
            pkgs.graphene
            pkgs.gdk-pixbuf
            pkgs.pango.out
            pkgs.harfbuzz
            pkgs.glib
          ];
          typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" giTypelibs;
        in pkgs.stdenv.mkDerivation {
          pname = "steam-loader";
          version = "1.0.0";

          src = ./src;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          buildInputs = [
            (pkgs.python3.withPackages (ps: [ ps.pygobject3 ]))
          ] ++ giTypelibs;

          installPhase = ''
            mkdir -p $out/bin $out/share/steam-loader
            cp steam-loader.py $out/share/steam-loader/

            makeWrapper ${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3 $out/bin/steam-loader \
              --add-flags "$out/share/steam-loader/steam-loader.py" \
              --set GI_TYPELIB_PATH "${typelibPath}" \
              --set LD_PRELOAD "${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so"
          '';

          meta = with pkgs.lib; {
            description = "Steam Big Picture loading screen for Niri/Wayland";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };

      in {
        packages = {
          default = steam-loader;
          steam-loader = steam-loader;
        };

        apps.default = {
          type = "app";
          program = "${steam-loader}/bin/steam-loader";
        };

        # Development shell for testing
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pygobject3
            gtk4
            libadwaita
            gtk4-layer-shell
            gobject-introspection
            niri
          ];

          shellHook = ''
            export GI_TYPELIB_PATH="${pkgs.gtk4}/lib/girepository-1.0:${pkgs.libadwaita}/lib/girepository-1.0:${pkgs.gtk4-layer-shell}/lib/girepository-1.0:$GI_TYPELIB_PATH"
          '';
        };
      }
    ) // {
      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.programs.steam-loader;
        in {
          options.programs.steam-loader = {
            enable = mkEnableOption "Steam Big Picture loading screen for Niri";
          };

          config = mkIf cfg.enable {
            environment.systemPackages = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.steam-loader
            ];
          };
        };

      # Home Manager module
      homeManagerModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.programs.steam-loader;
        in {
          options.programs.steam-loader = {
            enable = mkEnableOption "Steam Big Picture loading screen for Niri";
          };

          config = mkIf cfg.enable {
            home.packages = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.steam-loader
            ];
          };
        };
    };
}
