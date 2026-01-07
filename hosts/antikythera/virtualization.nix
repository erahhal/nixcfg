{ config, lib, pkgs, recursiveMerge, ... }:
{
  imports = [
    ../../profiles/virtual-machines.nix
  ];

  # Override Intel-specific settings inherited from virtual-machines.nix
  # This is an AMD system - Intel IOMMU and GVT-g don't apply

  # Use AMD-specific KVM nested virtualization (override Intel modprobe config)
  boot.extraModprobeConfig = lib.mkForce ''
    options kvm_amd nested=1
  '';

  # Only load AMD KVM module (not Intel)
  boot.kernelModules = [ "kvm-amd" ];

  # Enable containers and override Intel-specific virtualisation settings
  virtualisation = (
    let
      baseConfig = {
        # Disable Intel GVT-g (not applicable to AMD GPU)
        # This prevents i915.enable_gvt=1 from being added to kernel params
        kvmgt.enable = lib.mkForce false;

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
