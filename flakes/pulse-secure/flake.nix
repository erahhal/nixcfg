{
  description = "Pulse Secure VPN";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux = let
      pkgs = import "${nixpkgs}" {
        system = "x86_64-linux";
      };

    in with pkgs; {
      pulse-secure = callPackage ./pulse-secure.nix {
        inherit builtins;
      };
      default = self.packages.x86_64-linux.pulse-secure;
    };

    # TODO: usr/share/dbus-1/system.d/net.psecure.pulse.conf -> opt/pulsesecure/lib/JUNS/net.psecure.pulse.conf?
    # TODO: var/lib/pulsesecure/pulse
  };
}
