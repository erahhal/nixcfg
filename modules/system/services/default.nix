# Base system services (always-on)
{ pkgs, ... }:
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

  services.thermald = {
    enable = true;
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
