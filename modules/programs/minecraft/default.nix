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

  ## Generational ZGC, NOT Aikar's flags.
  ##
  ## Aikar's set is tuned for Paper/Spigot SERVERS and is the wrong shape here:
  ## Distant Horizons warns about both of its headline flags at world load.
  ##
  ##   -XX:+UseG1GC          -> "G1 Garbage collector detected. This can cause
  ##                            FPS stuttering. Recommended: ZGC (Java 21+)"
  ##   -XX:+DisableExplicitGC -> "Explicit Garbage Collection Disabled. This can
  ##                            cause out of memory crashes."
  ##
  ## The second one is not cosmetic. DH holds LOD data in large off-heap direct
  ## ByteBuffers, and those are only reclaimed when a GC runs over their Cleaner
  ## references -- which is exactly what System.gc() is for. Suppressing those
  ## calls at a 256-chunk radius trades a stutter for an eventual OOM. DH offers
  ## to silence the warning in its own config; silencing it would be treating
  ## the smoke detector.
  ##
  ## ZGC's pauses are sub-millisecond and independent of heap size, so the whole
  ## pile of G1 generation-sizing knobs has nothing to tune and is dropped.
  ##
  ## -Xmx/-Xms deliberately absent: they come from Prism's own memory fields,
  ## and specifying both makes Prism's setting the one that loses.
  ##
  ## ZGenerational is correct for JDK 21. It became the default in 23 and was
  ## removed in 24, so bumping javaPackage past 21 means dropping this flag --
  ## another reason the JDK is pinned rather than tracking latest.
  jvmArgs = lib.concatStringsSep " " [
    "-XX:+UseZGC"
    "-XX:+ZGenerational"
    "-XX:+AlwaysPreTouch"
    "-XX:+PerfDisableSharedMem"
  ];

  ## Prism's Java auto-detection scans the host and picks whatever it likes --
  ## on logistikon that was JDK 25, while 1.21.8 targets 21. JDK 24+ tightened
  ## sun.misc.Unsafe and restricted native access, which several Fabric mods
  ## still trip over, so leaving the choice to auto-detection makes the mod set
  ## work or not depending on which JDKs happen to be installed. Pin it.
  ##
  ## Referenced through a home-managed symlink rather than a raw store path:
  ## instance.cfg is seeded once and then owned by Prism, so a store path
  ## written into it would never be updated and would break the first time that
  ## JDK was garbage-collected. The symlink is re-pointed on every rebuild
  ## while the path inside instance.cfg stays constant.
  jdkLink = "${config.home.homeDirectory}/.local/share/PrismLauncher/jdk";

  instanceCfg = pkgs.writeText "instance.cfg" ''
    InstanceType=OneSix
    name=${cfg.instanceName} ${content.minecraftVersion}
    iconKey=default
    OverrideMemory=true
    MinMemAlloc=${toString cfg.minMemoryMiB}
    MaxMemAlloc=${toString cfg.maxMemoryMiB}
    OverrideJavaArgs=true
    JvmArgs=${jvmArgs}
    OverrideJavaLocation=true
    JavaPath=${jdkLink}/bin/java
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
        Pin rendering to the discrete NVIDIA GPU.

        MEASURED ON LOGISTIKON: glxinfo already reports the RTX 5090 with none
        of these variables set, because libglvnd reads 10_nvidia.json before
        50_mesa.json and so resolves to NVIDIA by default. This option is
        therefore not rescuing the game from the iGPU -- it is making an
        implicit choice explicit, and additionally pinning the Vulkan ICD and
        EGL vendor so a change in that file ordering cannot silently move
        rendering to the iGPU later.

        Note what it does NOT fix: on a host whose display hangs off the iGPU
        (logistikon scans out on the AMD at 71:00.0), frames still cross vendors
        to reach the screen no matter which GPU draws them. The only fix for
        that is plugging the monitor into the NVIDIA card.

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

    javaPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jdk21;
      defaultText = lib.literalExpression "pkgs.jdk21";
      description = ''
        JDK the instance runs on. Must match what the Minecraft version targets
        -- 1.21.x wants 21. Raising this is not a free upgrade: JDK 24+ blocks
        the native-access patterns some Fabric mods rely on.
      '';
    };

    renderDistance = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = ''
        Vanilla render distance seeded into options.txt.

        Deliberately LOW, which is backwards from how this dial normally works.
        Distant Horizons draws everything past this radius as LOD terrain, so
        vanilla render distance only decides where the expensive real chunks
        stop and the cheap LODs take over. Raising it does not extend the view
        -- DH already covers that out to lodChunkRenderDistanceRadius -- it just
        makes the same terrain get drawn twice. DH warns on startup when this is
        set too high; 8 is the value that silences it here.

        The LOD radius itself is set in-game rather than seeded, because DH's
        config schema is version-specific enough that generating it would break
        on a DH bump.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ launcher ];

    ## Stable path for instance.cfg's JavaPath to point at. Re-pointed on every
    ## rebuild, so a JDK bump does not strand the seeded instance.cfg.
    home.file.".local/share/PrismLauncher/jdk".source = cfg.javaPackage;

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
