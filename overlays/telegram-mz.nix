{ lib, pkgs, stdenv, ... }:

let telegram-mz = self: super: {
  telegram-mz = super.telegram-desktop.overrideAttrs (oldAttrs: {
    pname = "telegram-mz";

    buildInputs = oldAttrs.buildInputs or [] ++ [
      pkgs.makeWrapper
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r "$unwrapped/nix-support" "$out"
      cp -r "$unwrapped/share" "$out"
      cp -r "$unwrapped/bin/telegram-desktop" "$out/telegram-mz"
      runHook postInstall
    '';

    qtWrapperArgs = oldAttrs.qtWrapperArgs or [] ++ lib.optionals (stdenv.hostPlatform.isLinux) [
      "--add-flags -workdir ~/.mz"
    ];

    # postFixup = oldAttrs.postFixup or "" + ''
    #   wrapProgram $out/bin/telegram-desktop \
    #     --add-flags -workdir ~/.mz
    # '';
  });
};
in
{
  nixpkgs.overlays = [ telegram-mz ];
}
