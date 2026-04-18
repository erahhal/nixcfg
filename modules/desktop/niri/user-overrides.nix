{ config, ... }:
{
  nixcfg-niri.desktop.weather = {
    location = config.hostParams.desktop.location;
    coordinates = config.hostParams.desktop.coordinates;
    useFahrenheit = config.hostParams.desktop.useFahrenheit;
  };

  nixcfg-niri.desktop.killOnExit = config.hostParams.desktop.killOnExit;

  nixcfg-niri.desktop.cycleColumnsOnRepeatedWorkspaceFocus =
    config.hostParams.desktop.cycleColumnsOnRepeatedWorkspaceFocus;

  # Hybrid Intel+NVIDIA laptops: force startup-apps onto the Intel iGPU so screen
  # sharing works. AMD-only or single-GPU hosts skip this (sets wrong driver).
  nixcfg-niri.desktop.startupAppsForceIntelGpu =
    config.hostParams.gpu.intel.enable && config.hostParams.gpu.nvidia.enable;

  nixcfg-niri.desktop.terminal = config.hostParams.user.tty;
  nixcfg-niri.desktop.themeToggleCommand = "toggle-theme";

  nixcfg-niri.desktop.easyeffects = {
    generic = true;
    headphoneProfiles = true;
    laptopSpeakers = true;
    dolbyAtmos = true;
    thinkpadDolby = true;
  };
}
