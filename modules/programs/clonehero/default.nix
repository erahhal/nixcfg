{ config, pkgs, lib, ... }:

let
  cloneHeroFixed = pkgs.symlinkJoin {
    name = "clonehero-with-boot-config";
    paths = [ pkgs.clonehero ];
    buildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      # Create boot.config next to the binary
      cat > $out/bin/boot.config <<EOF
audio.buffer-size=1024
gfx-enable-native-gfx-jobs=0
memorysetup-main-allocator-block-size=33554432
memorysetup-thread-allocator-block-size=33554432
EOF

      # Wrap the binary to set environment variables and resource limits
      wrapProgram $out/bin/clonehero \
        --run 'ulimit -n unlimited 2>/dev/null || ulimit -n $(ulimit -Hn)' \
        --set MALLOC_CHECK_ 0 \
        --set MALLOC_PERTURB_ 0 \
        --set MALLOC_MMAP_THRESHOLD_ 131072 \
        --set MALLOC_TRIM_THRESHOLD_ 131072 \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.libpulseaudio ]}"
    '';
  };
in
{
  home.packages = [ cloneHeroFixed ];
}
