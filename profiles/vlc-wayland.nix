{ userParams, ... }:
{

  home-manager.users.${userParams.username} = {lib, pkgs, ... }: {
    home.packages = [
      # VLC uses XWayland instead of Wayland if $DISPLAY is set
      (pkgs.symlinkJoin {
        name = "vlc";
        paths = [ pkgs.vlc ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/vlc \
            --unset DISPLAY
        '';
      })
    ];

    # Override Desktop file so that wrapped version of VLC is called
    home.activation.steam = lib.hm.dag.entryAfter [ "installPackages" ] ''
      mkdir -p ~/.local/share/applications
      cp -rf /etc/profiles/per-user/${userParams.username}/share/applications/vlc.desktop ~/.local/share/applications/vlc.desktop
      sed -i 's#^Exec=.*#Exec=vlc --started-from-file %U#g' ~/.local/share/applications/vlc.desktop
      sed -i 's#^TryExec=.*#TryExec=vlc#g' ~/.local/share/applications/vlc.desktop
    '';

  };
}
