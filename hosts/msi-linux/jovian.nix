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
        gpu_device = 0;
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
      autoStart = true;
      desktopSession = "hyprland";
      user = userParams.username;
    };
  };

}
