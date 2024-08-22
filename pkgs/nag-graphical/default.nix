{ writeShellScriptBin, ... }:
writeShellScriptBin "nag-graphical" ''
if zenity --question --default-cancel --text="$1"; then
  $2
fi
''
