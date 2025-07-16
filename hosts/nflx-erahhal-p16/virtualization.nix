{ config, lib, pkgs, hostParams, recursiveMerge, ... }:
{
  imports = [
    ../../profiles/virtual-machines.nix
  ];

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  # Enable containers
  virtualisation = (
    let
      baseConfig = {
        oci-containers.backend = hostParams.containerBackend;
        containers = {
          enable = true;
        };
      };
      podmanConfig = {
        podman = {
          enable = true;
          dockerCompat = true;
          extraPackages = [ pkgs.zfs ];
        };
      };
      dockerConfig = {
        docker = {
          enable = true;
          daemon.settings = {
            # "exec-opts" = [ "native.cgroupdriver=systemd" ];
            "exec-opts" = [ "native.cgroupdriver=cgroupfs" ];
            "features" = { "buildkit" = true; };
            "experimental" = true;
            "default-cgroupns-mode" = "host";
            "cgroup-parent" = "docker.slice";
            "mtu" = 1400;
          };
        };
      };
    in
    if config.hostParams.containers.backend == "podman" then
      recursiveMerge [ baseConfig podmanConfig ]
    else
      recursiveMerge [ baseConfig dockerConfig ]
  );
}
