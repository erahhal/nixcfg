# Security: sudo, polkit, wrappers
{ debugMode, pkgs, ... }:
{
  security.sudo.wheelNeedsPassword = if debugMode then false else true;

  security.wrappers.udevil = {
    owner = "root";
    group = "root";
    source = "${pkgs.udevil}/bin/udevil";
    setuid = true;
  };
}
