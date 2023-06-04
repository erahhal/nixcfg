{ lib, ... }:
let
  # Need to escape bash variables so they aren't interpolated by home-manager during activation
  gimprc = builtins.replaceStrings ["\$"] ["\\$"] (builtins.readFile ./gimp-hidpi/gimprc);
  sessionrc = builtins.replaceStrings ["\$"] ["\\$"] (builtins.readFile ./gimp-hidpi/sessionrc);
in
{
  # Add high dpi theme for FIMP
  xdg.configFile."GIMP/2.10/themes/DarkHighDPI".source = ./gimp-hidpi/themes/DarkHighDPI;

  home.activation.gimpSettings = lib.hm.dag.entryAfter [ "installPackages" ]
    ''
      if [ ! -e ~/.config/GIMP/2.10/gimprc ]; then
        mkdir -p ~/.config/GIMP/2.10
        cat > ~/.config/GIMP/2.10/gimprc<< EOF
${gimprc}
EOF
      fi
      if grep --quiet "(theme "*")" ~/.config/GIMP/2.10/gimprc; then
        sed -i 's/(theme ".*")/(theme "DarkHighDPI")/g' ~/.config/GIMP/2.10/gimprc
      else
        echo '(theme "DarkHighDPI")' >> ~/.config/GIMP/2.10/gimprc
      fi

      if [ ! -e ~/.config/GIMP/2.10/sessionrc ]; then
        cat > ~/.config/GIMP/2.10/sessionrc<< EOF
${sessionrc}
EOF
      fi
      sed -i 's/(left-docks-width ".*")/(left-docks-width "346")/g' ~/.config/GIMP/2.10/sessionrc
    '';
}
