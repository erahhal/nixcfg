{ config, pkgs, recursiveMerge, ... }:
{
  imports = [
    ../../profiles/virtual-machines.nix
  ];

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  # Enable containers
  virtualisation = (
    let
      baseConfig = {
        oci-containers.backend = config.hostParams.containers.backend;
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
            "exec-opts" = [ "native.cgroupdriver=systemd" ];
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
