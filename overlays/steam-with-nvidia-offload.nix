{ lib, pkgs, stdenv, ... }:
let steamWithNvidiaOffload = self: super:
  let
    steam-runtime-wrapped = super.pkgsi686Linux.steamPackages.steam-runtime-wrapped;
    ldPath = super.lib.optionals super.stdenv.is64bit [ "/lib64" ]
    ++ [ "/lib32" ]
    ++ map (x: "/steamrt/${steam-runtime-wrapped.arch}/" + x) steam-runtime-wrapped.libs;
    # Zachtronics and a few other studios expect STEAM_LD_LIBRARY_PATH to be present
    exportLDPath = ''
      export LD_LIBRARY_PATH=${super.lib.concatStringsSep ":" ldPath}''${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH
      export STEAM_LD_LIBRARY_PATH="$STEAM_LD_LIBRARY_PATH''${STEAM_LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"
    '';
    # bootstrap.tar.xz has 444 permissions, which means that simple deletes fail
    # and steam will not be able to start
    fixBootstrap = ''
      if [ -r $HOME/.local/share/Steam/bootstrap.tar.xz ]; then
        chmod +w $HOME/.local/share/Steam/bootstrap.tar.xz
      fi
    '';
  in 
  {
  steam = super.steamPackages.steam-fhsenv.overrideAttrs (oldAttrs: rec {
    runScript = super.writeScript "steam-wrapper.sh" ''
      #!${super.runtimeShell}
      if [ -f /host/etc/NIXOS ]; then   # Check only useful on NixOS
        ${super.pkgsi686Linux.glxinfo}/bin/glxinfo >/dev/null 2>&1
        # If there was an error running glxinfo, we know something is wrong with the configuration
        if [ $? -ne 0 ]; then
          cat <<EOF > /dev/stderr
      **
      WARNING: Steam is not set up. Add the following options to /etc/nixos/configuration.nix
      and then run \`sudo nixos-rebuild switch\`:
      {
        hardware.opengl.driSupport32Bit = true;
        hardware.pulseaudio.support32Bit = true;
      }
      **
      EOF
        fi
      fi
      ${exportLDPath}
      ${fixBootstrap}
      exec nvidia-offload steam "$@"
    '';
  });
};
in
{
  nixpkgs.overlays = [ steamWithNvidiaOffload ];
}
