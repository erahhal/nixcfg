## Prism Launcher plus a pinned, reproducible "Realism" instance.
##
## Home-manager module (imported from a host's user.nix, like ../clonehero),
## because a Minecraft instance is user data, not system state.
##
## THE SPLIT THIS MODULE ENFORCES, and why it is not simply `home.file`:
## Prism and Minecraft both rewrite their own config at runtime. Pointing
## home.file at options.txt makes it a read-only store symlink, and the game
## then fails to save video settings with no error the player will ever see.
## So content that nix owns (mods, shaderpacks, resourcepacks) is COPIED in,
## and config that the applications own (options.txt, iris.properties, saves,
## accounts.json) is only SEEDED WHEN ABSENT and never touched again.
##
## The copy is manifest-tracked rather than `rsync --delete`: a file that a
## previous generation installed and this one dropped gets retired, but a mod
## dropped in by hand is left alone. Wiping hand-added mods on every rebuild
## would make the declarative setup actively worse than the imperative one it
## replaces.
{ config, lib, pkgs, ... }:

let
  cfg = config.nixcfg.programs.minecraft;

  content = pkgs.callPackage ../../../pkgs/minecraft-realism { };

  instanceDir = "${config.home.homeDirectory}/.local/share/PrismLauncher/instances/${cfg.instanceName}";
  mcDir = "${instanceDir}/.minecraft";

  ## Wrap the launcher rather than using Prism's per-instance WrapperCommand.
  ## WrapperCommand would have to name a store path inside instance.cfg, which
  ## is a seeded-once mutable file -- so it would go stale at the first rebuild
  ## and silently stop offloading. Env set on the launcher is inherited by the
  ## JVM it spawns, so wrapping here covers the game too.
  ##
  ## Mirrors overlays/blender-with-nvidia-offload.nix.
  launcher =
    if !cfg.nvidiaOffload then pkgs.prismlauncher
    else pkgs.symlinkJoin {
      name = "prismlauncher-nvidia-offload";
      paths = [ pkgs.prismlauncher ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/prismlauncher \
          --set __NV_PRIME_RENDER_OFFLOAD 1 \
          --set __GLX_VENDOR_LIBRARY_NAME nvidia \
          --set __VK_LAYER_NV_optimus NVIDIA_only \
          --set VK_ICD_FILENAMES /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json \
          --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
      '';
    };

  mmcPack = pkgs.writeText "mmc-pack.json" (builtins.toJSON {
    formatVersion = 1;
    components = [
      { uid = "net.minecraft"; version = content.minecraftVersion; important = true; }
      { uid = "net.fabricmc.fabric-loader"; version = content.fabricLoaderVersion; }
    ];
  });

  ## Aikar's G1GC set. -Xmx/-Xms come from Prism's own memory fields, so they
  ## are deliberately absent here -- specifying both makes Prism's setting the
  ## one that loses, which is confusing when tuning later.
  jvmArgs = lib.concatStringsSep " " [
    "-XX:+UseG1GC" "-XX:+ParallelRefProcEnabled" "-XX:MaxGCPauseMillis=200"
    "-XX:+UnlockExperimentalVMOptions" "-XX:+DisableExplicitGC" "-XX:+AlwaysPreTouch"
    "-XX:G1NewSizePercent=30" "-XX:G1MaxNewSizePercent=40" "-XX:G1HeapRegionSize=8M"
    "-XX:G1ReservePercent=20" "-XX:G1HeapWastePercent=5" "-XX:G1MixedGCCountTarget=4"
    "-XX:InitiatingHeapOccupancyPercent=15" "-XX:G1MixedGCLiveThresholdPercent=90"
    "-XX:G1RSetUpdatingPauseTimePercent=5" "-XX:SurvivorRatio=32"
    "-XX:+PerfDisableSharedMem" "-XX:MaxTenuringThreshold=1"
  ];

  instanceCfg = pkgs.writeText "instance.cfg" ''
    InstanceType=OneSix
    name=${cfg.instanceName} ${content.minecraftVersion}
    iconKey=default
    OverrideMemory=true
    MinMemAlloc=${toString cfg.minMemoryMiB}
    MaxMemAlloc=${toString cfg.maxMemoryMiB}
    OverrideJavaArgs=true
    JvmArgs=${jvmArgs}
    OverrideWindow=true
    LaunchMaximized=true
  '';

  ## builtins.toJSON emits exactly the ["a","b"] form options.txt expects.
  resourcePacksLine =
    builtins.toJSON ([ "vanilla" ] ++ map (n: "file/${n}") content.defaults.resourcePacks);

  optionsTxt = pkgs.writeText "options.txt" ''
    renderDistance:${toString cfg.renderDistance}
    simulationDistance:12
    maxFps:260
    enableVsync:false
    graphicsMode:1
    ao:true
    mipmapLevels:4
    biomeBlendRadius:5
    entityDistanceScaling:3.0
    particles:0
    fov:0.25
    guiScale:0
    fullscreen:false
    resourcePacks:${resourcePacksLine}
    incompatibleResourcePacks:[]
  '';

  irisProperties = pkgs.writeText "iris.properties" ''
    enableShaders=true
    shaderPack=${content.defaults.shaderPack}
    disableUpdateMessage=true
    maxShadowRenderDistance=32
    colorSpace=SRGB
  '';

in
{
  options.nixcfg.programs.minecraft = {
    enable = lib.mkEnableOption "Prism Launcher with the pinned Realism instance";

    instanceName = lib.mkOption {
      type = lib.types.str;
      default = "Realism";
      description = "Prism instance directory name (also its instance ID).";
    };

    nvidiaOffload = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Render on the discrete NVIDIA GPU via PRIME offload.

        Needed on hosts where the display hangs off an iGPU but a faster NVIDIA
        card is present -- logistikon scans out on the AMD iGPU while the RTX
        5090 sits on the PCIe slot, so without this the game silently renders on
        the iGPU. Harmless where the NVIDIA card already drives the display: the
        offload flag simply has nothing to offload from.

        Leave false on AMD/Intel-only hosts.
      '';
    };

    minMemoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = "Prism MinMemAlloc, in MiB.";
    };

    maxMemoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12288;
      description = ''
        Prism MaxMemAlloc, in MiB.

        Resist raising this just because the host has RAM to spare: G1 pause
        times grow with heap size, so an oversized heap makes the stutter it is
        meant to fix worse. Distant Horizons wants page cache and its own LOD
        cache, neither of which lives in the JVM heap.
      '';
    };

    renderDistance = lib.mkOption {
      type = lib.types.ints.positive;
      default = 32;
      description = ''
        Vanilla render distance seeded into options.txt. Distant Horizons draws
        everything beyond this as LOD terrain and is configured in-game, not
        here -- its config schema is version-specific enough that generating it
        would break on a DH bump.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ launcher ];

    home.activation.minecraft-realism =
      lib.hm.dag.entryAfter [ "installPackages" ] ''
        instanceDir="${instanceDir}"
        mcDir="${mcDir}"

        mkdir -p "$mcDir/config"

        ## Content nix owns. Manifest-tracked so hand-added mods survive.
        syncGroup() {
          group="$1"
          src="${content}/$group"
          dst="$mcDir/$group"
          manifest="$mcDir/.nix-managed-$group"

          mkdir -p "$dst"

          new="$(mktemp)"
          ( cd "$src" && ls -1 ) > "$new"

          ## Retire only what a previous generation put there. A file absent
          ## from the old manifest was added by hand and is not ours to remove.
          if [ -f "$manifest" ]; then
            while IFS= read -r f; do
              [ -n "$f" ] || continue
              grep -qxF "$f" "$new" || rm -f "$dst/$f"
            done < "$manifest"
          fi

          ## Store files are mode 444, but Prism disables a mod by renaming it,
          ## so the copies have to be writable.
          cp -f "$src"/* "$dst"/
          chmod -R u+w "$dst"

          mv "$new" "$manifest"
        }

        syncGroup mods
        syncGroup shaderpacks
        syncGroup resourcepacks

        ## Config the applications own. Seed once, then never touch -- these
        ## are rewritten by Prism and Minecraft at runtime.
        seed() {
          if [ ! -e "$1" ]; then
            cp "$2" "$1"
            chmod u+w "$1"
          fi
        }

        seed "$instanceDir/mmc-pack.json"     "${mmcPack}"
        seed "$instanceDir/instance.cfg"      "${instanceCfg}"
        seed "$mcDir/options.txt"             "${optionsTxt}"
        seed "$mcDir/config/iris.properties"  "${irisProperties}"
      '';
  };
}
