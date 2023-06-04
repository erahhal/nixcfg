{ lib, hostParams, ... }:
let
  # Need to escape bash variables so they aren't interpolated by home-manager during activation
  configFile = builtins.replaceStrings ["\$"] ["\\$"] (builtins.readFile ./qt4-hidpi/Trolltech.conf);
in
{
  home.activation.qt4Config = lib.hm.dag.entryAfter [ "installPackages" ] ''
    if [ ! -e ~/.config/Trolltech.conf ]; then
      cat > ~/.config/Trolltech.conf<< EOF
[Qt]
${configFile}
EOF
    fi

    if grep --quiet "font=" ~/.config/Trolltech.conf; then
      sed -i 's/font=.*$/font="Sans Serif,${toString hostParams.trolltechFontSize},-1.5,50,0,0,0,0,0"/g' ~/.config/Trolltech.conf
    elif ! grep --quiet "\[Qt\]" ~/.config/Trolltech.conf; then
      cat >> ~/.config/Trolltech.conf<< EOF

[Qt]
${configFile}
EOF
    else
      sed -i '/^\[Qt\]/a font="Sans Serif,${toString hostParams.trolltechFontSize},-1.5,50,0,0,0,0,0"' ~/.config/Trolltech.conf
    fi
  '';
}
