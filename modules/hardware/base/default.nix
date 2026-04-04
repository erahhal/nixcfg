# Base hardware config: firmware, GPU drivers
{ ... }:
{
  hardware.enableAllFirmware = true;

  imports = [
    ../gfx-nvidia
    ../gfx-amd
    ../gfx-intel
  ];
}
