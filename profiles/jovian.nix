{ userParams, ... }:
{

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility"; # For systems with AMD GPUs
        gpu_device = 1;
        amd_performance_level = "high";
      };
    };
  };

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  jovian = {
    steam = {
      enable = true;
      autoStart = false;
      # desktopSession = "niri";
      user = userParams.username;
      # desktopSession = "steam";
      desktopSession = "gamescope-wayland";
    };
  };

  nix.settings.extra-platforms = [ "i686-linux" ];
  nix.settings.sandbox = true;
  boot.binfmt.emulatedSystems = [ "i686-linux" ];
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  # boot.kernel.sysctl."abi.vsyscall32" = 1;
}
