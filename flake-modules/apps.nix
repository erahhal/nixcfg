{ ... }:
{
  perSystem = { pkgs, ... }:
  let
    mkApp = name: { runtimeInputs ? [], text }: {
      type = "app";
      program = "${pkgs.writeShellApplication {
        inherit name runtimeInputs text;
      }}/bin/${name}";
    };

    hostname = "\"$(hostname)\"";

    # Common cleanup steps run before/after switch
    preSwitch = ''
      # Clear mimeapps if not a symlink (gets overwritten by desktop environments)
      [ -L "''${HOME}/.config/mimeapps.list" ] || rm -f "''${HOME}/.config/mimeapps.list"

      # Clear GPU cache
      mkdir -p "''${HOME}/.config"
      find "''${HOME}/.config/." -type d -name GPUCache -exec rm -rf {} + 2>/dev/null || true

      # Plasma6 overwrites this, messing up the dark theme
      rm -f "''${HOME}/.gtkrc-2.0"
    '';

    postSwitch = ''
      # Fix gnupg permissions
      mkdir -p "''${HOME}/.gnupg"
      chmod 700 "''${HOME}/.gnupg"

      # Restore theme if build changed it
      CURR_THEME="''${CURR_THEME:-}"
      if [ -n "$CURR_THEME" ]; then
        NEW_THEME=$(cat "''${HOME}/.system-theme" 2>/dev/null || echo "")
        if [ "$CURR_THEME" != "$NEW_THEME" ]; then
          systemctl --user restart toggle-theme || true
        fi
      fi
    '';

    buildAndSwitch = { extraArgs ? "" }: ''
      CURR_THEME=$(cat "''${HOME}/.system-theme" 2>/dev/null || echo "")
      ${preSwitch}
      nixos-rebuild switch --sudo --flake .#${hostname} ${extraArgs} -L
      ${postSwitch}
    '';
  in {
    apps = {
      switch = mkApp "nixcfg-switch" {
        text = buildAndSwitch {};
      };

      debug = mkApp "nixcfg-debug" {
        text = buildAndSwitch {
          extraArgs = "--show-trace --override-input debug-mode github:boolean-option/true";
        };
      };

      boot = mkApp "nixcfg-boot" {
        text = ''
          nixos-rebuild boot --sudo --flake .#${hostname} -L
        '';
      };

      show-trace = mkApp "nixcfg-show-trace" {
        text = ''
          ${preSwitch}
          nixos-rebuild switch --sudo --show-trace --flake .#${hostname} -L
          ${postSwitch}
        '';
      };

      offline = mkApp "nixcfg-offline" {
        text = ''
          nixos-rebuild switch --sudo --offline --option binary-caches "" --flake .#${hostname} -L
        '';
      };

      nflx-local = mkApp "nixcfg-nflx-local" {
        text = buildAndSwitch {
          extraArgs = "--show-trace --override-input debug-mode github:boolean-option/true --override-input nflx-nixcfg ~/Code/nflx-nixcfg";
        };
      };

      nflx-vpn = mkApp "nixcfg-nflx-vpn" {
        text = buildAndSwitch {
          extraArgs = "--show-trace --override-input debug-mode github:boolean-option/true --override-input nflx-nixcfg ~/Code/nflx-nixcfg --override-input nflx-nixcfg/nm-openconnect-pulse-sso ~/Code/nm-openconnect-pulse-sso";
        };
      };

      nixvim-local = mkApp "nixcfg-nixvim-local" {
        text = buildAndSwitch {
          extraArgs = "--show-trace --override-input debug-mode github:boolean-option/true --override-input nixvim-config ~/Code/nixvim-config";
        };
      };

      secrets-local = mkApp "nixcfg-secrets-local" {
        text = buildAndSwitch {
          extraArgs = "--show-trace --override-input debug-mode github:boolean-option/true --override-input secrets ~/Code/nixcfg-secrets";
        };
      };

      update = mkApp "nixcfg-update" {
        text = ''
          nix flake update
        '';
      };

      update-nflx = mkApp "nixcfg-update-nflx" {
        text = ''
          nix flake lock --update-input nflx --update-input nflx-vpn --update-input openconnect-pulse-launcher
        '';
      };

      update-secrets = mkApp "nixcfg-update-secrets" {
        text = ''
          nix flake lock --update-input secrets
        '';
      };

      upgrade = mkApp "nixcfg-upgrade" {
        text = ''
          nix flake update
          ${buildAndSwitch {}}
        '';
      };

      gc = mkApp "nixcfg-gc" {
        text = ''
          nix-store --gc
          nix-env --delete-generations old
        '';
      };

      remote-install = mkApp "nixcfg-remote-install" {
        text = builtins.readFile ../nixos-anywhere/install.sh;
      };

      get-new-packages = mkApp "nixcfg-get-new-packages" {
        runtimeInputs = [ pkgs.nvd ];
        text = ''
          nix build --override-input nixpkgs github:NixOS/nixpkgs/nixos-24.05 -v .#nixosConfigurations."${hostname}".config.system.build.toplevel
          nvd diff /run/current-system result
          rm result
        '';
      };
    };
  };
}
