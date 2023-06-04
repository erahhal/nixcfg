{ pkgs, secrets, ... }:
let
  wg0-up = pkgs.writeShellScriptBin "wg0-up" ''
    nmcli connection up wg0 passwd-file ${secrets.wireguard-private-nm-passwd-file.path}
  '';
  wg0-down = pkgs.writeShellScriptBin "wg0-down" ''
    nmcli connection down wg0
  '';
in
pkgs.symlinkJoin {
  name = "wg0-scripts";
  paths = [
    wg0-up
    wg0-down
  ];
}
