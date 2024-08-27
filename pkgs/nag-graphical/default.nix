{ writeShellScriptBin, ... }:
writeShellScriptBin "nag-graphical" ''
if zenity --question --text="$1" $3 $4 $5; then
  $2
fi
''
