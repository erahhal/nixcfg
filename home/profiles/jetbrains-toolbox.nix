{ pkgs, ... }:
  let jetbrains-toolbox-nogpu = self: super: {
    jetbrains-toolbox = super.jetbrains-toolbox.overrideAttrs (old: {
      # add `makeWrapper` to existing dependencies
      buildInputs = (old.buildInputs or []) ++ [ pkgs.makeWrapper ];
      # wrap the binary in a script where the appropriate env var is set
      postInstall = old.postInstall or "" + ''
        wrapProgram "$out/bin/jetbrains-toolbox" \
          --add-flags "--graphics-api software"
      '';
    });
  };
in
{
  nixpkgs.overlays = [ jetbrains-toolbox-nogpu ];

  home.packages = with pkgs; [
    jetbrains-toolbox
    ## These are installed by jetbrains-toolbox with a corporate license
    # jetbrains.datagrip
    # jetbrains.idea-ultimate
  ];

  # This is needed to create a .desktop entry which is currently broken
  home.file.".local/share/applications/jetbrains-toolbox.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=JetBrains Toolbox
    Exec=${pkgs.jetbrains-toolbox}/bin/jetbrains-toolbox
    Icon=jetbrains-toolbox
    StartupNotify=false
    Terminal=false
    MimeType=x-scheme-handler/jetbrains;
    X-AppImage-Integrate=false
  '';

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "x-scheme-handler/jetbrains" = [ "jetbrains-toolbox.desktop" ];
    };
    defaultApplications = {
      "x-scheme-handler/jetbrains" = [ "jetbrains-toolbox.desktop" ];
    };
  };
}
