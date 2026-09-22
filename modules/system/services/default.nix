# Base system services (always-on)
{ config, lib, pkgs, ... }:
{
  services.ntp.enable = true;
  systemd.coredump.enable = true;
  services.fwupd.enable = true;
  services.logind.settings.Login.KillUserProcesses = false;

  # Network discovery (scanners, printers, media devices)
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # Eternal terminal
  services.eternal-terminal.enable = true;
  networking.firewall.allowedTCPPorts = [ 2022 ];
  environment.variables = {
    ET_NO_TELEMETRY = "1";
  };

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Auto-mount optical disks
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.udev.extraRules = ''
    ACTION=="change", KERNEL=="sr0", ENV{DISK_MEDIA_CHANGE}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart devmon@$env{USER}.service"
  '';

  services.openssh.enable = true;

  ## thermald IS INTEL-ONLY, AND ENABLING IT FLEET-WIDE COSTS EVERY AMD
  ## HOST A PERMANENTLY FAILING UNIT. It drives Intel P-state, RAPL and
  ## DTS; on AMD it looks for the `coretemp` sysfs, finds none, and exits 1
  ## at init — measured on logistikon (Ryzen 7 9700X), where the sensors
  ## that DO exist are k10temp, amdgpu, nvme and spd5118, none of which it
  ## can read. `ignoreCpuidCheck` below is why it gets that far: the flag
  ## exists to force thermald onto CPUs it does not recognise, so instead
  ## of declining it proceeds and then fails on sensor discovery.
  ##
  ## THE COST IS NOT THE DAEMON, IT IS THE EXIT CODE.
  ## `switch-to-configuration` returns 4 if any unit fails to start, so on
  ## an AMD host every single `nixos-rebuild` reports failure — and the
  ## habit of reading "exit 4" as "just thermald" is how a real unit
  ## failure gets waved past.
  ##
  ## GATED ON AMD RATHER THAN ON INTEL, and that asymmetry is deliberate.
  ## The obvious spelling — enable only where `hardware.cpu.intel.*` is
  ## set — was tried and is a REGRESSION: nflx-erahhal-p16 is an Intel
  ## machine that declares no microcode option, so it would have lost
  ## thermald silently. Keying off AMD instead only ever turns it OFF, and
  ## only where a host has positively said it is AMD. A host that declares
  ## nothing keeps today's behaviour.
  ##
  ## So the fix for an AMD box is to declare its CPU, which it should be
  ## doing anyway for microcode — that is what logistikon was missing.
  services.thermald = {
    enable = lib.mkDefault (!config.hardware.cpu.amd.updateMicrocode);
    ignoreCpuidCheck = true;
  };

  services.upower.enable = true;

  imports = [
    ../../services/macchanger
    ../../services/printers-scanners
    ../../programs/flox
    ../../../nixos-anywhere/connection-sharing.nix
  ];
}
