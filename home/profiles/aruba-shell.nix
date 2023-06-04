{ pkgs, ... }:
let
  aruba-shell = pkgs.writeScriptBin "aruba-shell" ''
    #!${pkgs.stdenv.shell}

    echo "Press <ENTER> to see login prompt."
    echo "Username is \"admin\"."
    echo ""
    echo "To get IP address associated with VLAN and"
    echo "make web gui accessible:"
    echo ""
    echo " (aruba) enable"
    echo " (aruba) configure terminal"
    echo " (aruba) (config) vlan 1"
    echo " (aruba) (VLAN \"1\") ip address dhcp-client"
    echo " (aruba) exit"
    echo ""
    echo ""
    echo "Press any key to continue."
    echo ""
    read -n 1 -s
    clear
    echo ""
    echo "Loading..."

    ${pkgs.minicom}/bin/minicom -c on ttyUSB1
  '';
in {
  home.packages = [ aruba-shell ];

  home.file.".minirc.ttyUSB1".text = ''
    # Machine-generated file - use setup menu in minicom to change parameters.
    pu port             /dev/ttyUSB1
    pu baudrate         9600
    pu bits             8
    pu parity           N
    pu stopbits         1
    pu mdialpre
    pu mdialsuf
    pu mdialpre2
    pu mdialsuf2
    pu mdialpre3
    pu mdialsuf3
    pu mconnect
    pu mhangup
    pu rtscts           No
  '';
}
