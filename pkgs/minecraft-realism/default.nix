## Pinned client-side content for the "Realism" Minecraft instance.
##
## Every entry is a Modrinth CDN URL carrying an SRI hash derived from
## Modrinth's own sha512. The set was generated from the exact files that were
## installed and smoke-tested against 1.21.8 -- so this pins the TESTED set,
## not "whatever the API resolves today". That distinction is the whole point:
## re-resolving on each build would make the instance drift silently, and a
## Minecraft mod set that drifts is a mod set that stops launching.
##
## To bump a mod, replace its url AND hash together. Mixing a new url with an
## old hash fails the fixed-output check rather than installing the wrong jar,
## which is the failure mode you want.
##
## Deliberately NOT here: Physics Mod (CurseForge-only, no stable CDN URL) and
## Patrix/Stratum (paid Patreon downloads). Those stay manual drops.
{ lib, stdenvNoCC, fetchurl }:

let
  ## Store path names may not contain spaces, brackets or parens, and several
  ## resourcepacks have all three. Fetch under a sanitized name but install
  ## under the real one -- Minecraft matches resource packs by exact filename,
  ## so the name options.txt refers to has to survive the round trip intact.
  storeName = builtins.replaceStrings [ " " "[" "]" "(" ")" ] [ "-" "-" "-" "-" "-" ];

  fetch = e: fetchurl {
    name = storeName e.name;
    inherit (e) url hash;
  };

  sources = {
    mods = [
      # fabric-api             0.136.1+1.21.8
      { name = "fabric-api-0.136.1+1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/P7dR8mSH/versions/g58ofrov/fabric-api-0.136.1%2B1.21.8.jar";
        hash = "sha512-6xprX8mRLGhAlJPxD0PDthrdodeJ7enIOxbQqVouuWvWMEcoZuFjlgR56xtNEZbQmt5arcnaYmJOgAZAxwbEqQ=="; }
      # sodium                 mc1.21.8-0.7.3-fabric
      { name = "sodium-fabric-0.7.3+mc1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/AANobbMI/versions/7pwil2dy/sodium-fabric-0.7.3%2Bmc1.21.8.jar";
        hash = "sha512-LH/pmM19IMbezclE33M9uHCrNkpkz9vUxQTB9PEdPkHcGylVXnP7r8BRtMT7+9e1Ji0Tudh09LG4hg3orv6sUw=="; }
      # sodium-extra           mc1.21.8-0.7.0+fabric
      { name = "sodium-extra-fabric-0.7.0+mc1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/PtjYWJkn/versions/Of25zuEG/sodium-extra-fabric-0.7.0%2Bmc1.21.8.jar";
        hash = "sha512-HbNZ0YE60WiFhgsgDQ7BpzWC8Yaz98aKUja9fhGSDXVxFYeH2J5lmltehfmxRvF4EtNIPs0o+r3WzaY5ci4CPA=="; }
      # iris                   1.9.6+1.21.8-fabric
      { name = "iris-fabric-1.9.6+mc1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/YL57xq9U/versions/Rhzf61g1/iris-fabric-1.9.6%2Bmc1.21.8.jar";
        hash = "sha512-e7wJRGL7BbAIBRYy6UTOJ0zprVe9z53WYI7YFLdunOUw6g/2ZZPsWVWJmqpGh34l5aZ91GxIAPKUGf2Mf7Uxuw=="; }
      # lithium                mc1.21.8-0.18.1-fabric
      { name = "lithium-fabric-0.18.1+mc1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/qxIL7Kb8/lithium-fabric-0.18.1%2Bmc1.21.8.jar";
        hash = "sha512-7z4IIMfIMcNSy9WvpKH0/3PbD6PE5EKLo1rS+uuOe86K5IBaBJNL6CCZASREpwwKLPIEnyr5X+aIyoTZTRxGcg=="; }
      # ferrite-core           8.0.4-fabric
      { name = "ferritecore-8.0.4-fabric.jar";
        url  = "https://cdn.modrinth.com/data/uXXizFIs/versions/LdlksamY/ferritecore-8.0.4-fabric.jar";
        hash = "sha512-i+bEmqWQD0NMCC9QWkjPa6/HC7Q+m51ODkJSRgXS0i+Wi8OgwASBkKUpb9PMaW2MOnMp3IoCJ5L5IOg+zkfltg=="; }
      # entityculling          1.10.5
      { name = "entityculling-fabric-1.10.5-mc1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/NNAgCjsB/versions/YKwzKRuH/entityculling-fabric-1.10.5-mc1.21.8.jar";
        hash = "sha512-6X3OjgeHQe1sygWqqOvWVPqyWcQw/IRpx3PglX8L66OuO4P4mTpiJ9pG6k53LnAFko4S0PuWhKfcWcsEMU+vdw=="; }
      # immediatelyfast        1.12.6+1.21.8-fabric
      { name = "ImmediatelyFast-Fabric-1.12.6+1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/5ZwdcRci/versions/zihthChu/ImmediatelyFast-Fabric-1.12.6%2B1.21.8.jar";
        hash = "sha512-rXwBkLlS1HFKd0N9kfxY638llV8cRChzsp2wYHkSEMgNCrxtXeAxPM7U1SdL6/crlGCvnxcDdIg2KtsXuvFR8Q=="; }
      # dynamic-fps            3.11.4
      { name = "dynamic-fps-3.11.4+minecraft-1.21.6-fabric.jar";
        url  = "https://cdn.modrinth.com/data/LQ3K71Q1/versions/OnRerL4D/dynamic-fps-3.11.4%2Bminecraft-1.21.6-fabric.jar";
        hash = "sha512-jMct1giMj07V8oCLYZrB7GvWThrhxREhX3vlsbIXdTo67UFj8zwTP6pawpyw4QpSWqmEARapZxSfN0AVCPKY0A=="; }
      # distanthorizons        3.2.0-b-1.21.8
      { name = "DistantHorizons-3.2.0-b-1.21.8-fabric-neoforge.jar";
        url  = "https://cdn.modrinth.com/data/uCdwusMi/versions/WRln6VDv/DistantHorizons-3.2.0-b-1.21.8-fabric-neoforge.jar";
        hash = "sha512-o8vbOI70KizxfZKdYO6Bu05TvJMntPd1UqEn29yp0+yIcxHcJmzFK0RC8SGLnla1smdF0Yxim4nnYCXRfO7/0Q=="; }
      # euphoria-patches       1.9.3-r5.8.1-fabric
      { name = "EuphoriaPatcher-1.9.3-r5.8.1-fabric.jar";
        url  = "https://cdn.modrinth.com/data/4H6sumDB/versions/7GNWrkGL/EuphoriaPatcher-1.9.3-r5.8.1-fabric.jar";
        hash = "sha512-xEvbg/ee5KY6PzAJ5r8AMyDp1bs9aBxImOIZ1EIU5E16Y8ywQn+eE/KbUfs9yP4CcIf4tpDQNr4OMc8356O7Hg=="; }
      # entitytexturefeatures  7.1-fabric-1.21.6
      { name = "entity_texture_features_1.21.6-fabric-7.1.jar";
        url  = "https://cdn.modrinth.com/data/BVzZfTc1/versions/LhiABkEc/entity_texture_features_1.21.6-fabric-7.1.jar";
        hash = "sha512-3SsscQJzxOtGnQNh3Qb1F+HBFZDd21MfFg+V9iA0ErlIAcHPbFL83AjVC7dnFL7AGyaVjm9Hlbr9CMYEs39+Yg=="; }
      # entity-model-features  3.2.4-fabric-1.21.6
      { name = "entity_model_features-3.2.4-1.21.6-fabric.jar";
        url  = "https://cdn.modrinth.com/data/4I1XuqiY/versions/rPlvbW7d/entity_model_features-3.2.4-1.21.6-fabric.jar";
        hash = "sha512-DvF4vLwAtkAqtEPud/813Zj16N4oO1D3J0BfvgV6zmMShM+fL2sraVygguOdGZexeK6NzrkSH8KbV4Nb5K82vQ=="; }
      # continuity             3.0.1-beta.1+1.21.6
      { name = "continuity-3.0.1-beta.1+1.21.6.jar";
        url  = "https://cdn.modrinth.com/data/1IjD5062/versions/m0cvWhzT/continuity-3.0.1-beta.1%2B1.21.6.jar";
        hash = "sha512-lbGkUp2OSnFU3IIpTkcz1imu8QJaLsqkjwT0l24C6OFawLKjW1Z2Lgf1Hb6+WdzhLktA0CkZJOcEkPkeGmfa7Q=="; }
      # terralith              2.5.13
      { name = "Terralith_1.21.x_v2.5.13.jar";
        url  = "https://cdn.modrinth.com/data/8oi3bsk5/versions/JKg71Gq0/Terralith_1.21.x_v2.5.13.jar";
        hash = "sha512-MQOHnvOQ1Hpo8QvUvxudQGOWkFr6ZAuMFcOkTIwVu8PG/cTqtalGtr4ViFExQI9s1pjEqNIGUUSyqxxG+nEM2w=="; }
      # tectonic               3.0.13
      { name = "tectonic-3.0.13-fabric-1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/lWDHr9jE/versions/G6Ed4Wsp/tectonic-3.0.13-fabric-1.21.8.jar";
        hash = "sha512-IU68H+i3c19kIRg1wUFhzQzsnE8Eu1nlmf5/fw/bAOqgXonsA3Bp+3wrKAKlajWWpobla5G06IDKpb62UKT+Pw=="; }
      ## Hard dependency of tectonic (>=1.4.11). Tectonic's Modrinth
      ## `dependencies` field is EMPTY -- the requirement exists only inside its
      ## fabric.mod.json -- so resolving deps from the API alone silently
      ## produces a mod set that fails at Knot init. Verify additions by reading
      ## every jar's fabric.mod.json (including the modules nested inside
      ## fabric-api), not by trusting Modrinth metadata.
      #
      # lithostitched          1.4.11-fabric-1.21.6  (declares mc >=1.21)
      { name = "lithostitched-fabric-1.21.6-1.4.11.jar";
        url  = "https://cdn.modrinth.com/data/XaDC71GB/versions/ROo8a9VV/lithostitched-fabric-1.21.6-1.4.11.jar";
        hash = "sha512-HWMZLbotzBbxVlLzEoo5DaWC+1vgmkqhrTgFyAXaD/87FfvK3h676dUD6uwb2ko+BjkCq6PW7soOuLzm/N24WQ=="; }
      # modmenu                15.0.2
      { name = "modmenu-15.0.2.jar";
        url  = "https://cdn.modrinth.com/data/mOgUt4GM/versions/ku5NivOP/modmenu-15.0.2.jar";
        hash = "sha512-4cgSJ9ZHFboHVaV1JzCYP6GM0u5LK0GmBUXs34sIRcl3MW54HVgeM+uGmSuBamsf6SojRe33LBYSh6T6PUD+wg=="; }
      # cloth-config           19.0.147+fabric
      { name = "cloth-config-19.0.147-fabric.jar";
        url  = "https://cdn.modrinth.com/data/9s6osm5g/versions/cz0b1j8R/cloth-config-19.0.147-fabric.jar";
        hash = "sha512-kkt+m/baZwuTbD6vOiunkEoF7/T9cSrPjuYuWHdwwFoiUQnTwL3wFZkuhwlF0ghqoA5zj5CzsQnjZLAQXAiHWg=="; }
      # placeholder-api        2.7.2+1.21.8
      { name = "placeholder-api-2.7.2+1.21.8.jar";
        url  = "https://cdn.modrinth.com/data/eXts2L7r/versions/1S1kjZ9W/placeholder-api-2.7.2%2B1.21.8.jar";
        hash = "sha512-ZsIGeOgymwEpQHqwRcFx4+IqXKE1RLH7z1rblfcPa7bLn7TZoiMcrHuV4ytrJq5zK2FtxDf5yScyW7IMIKVawQ=="; }
    ];

    shaderpacks = [
      # complementary-unbound     r5.8.1
      { name = "ComplementaryUnbound_r5.8.1.zip";
        url  = "https://cdn.modrinth.com/data/R6NEzAwj/versions/VMHXIk50/ComplementaryUnbound_r5.8.1.zip";
        hash = "sha512-kJjdngwYuA96uig5zqM86aYU2XZlu/ysh8zObkdxZnxBYC2ZCIhSyxZCzKsgss7/m5ivjy55W9DTuQt8nLq5FA=="; }
      # complementary-reimagined  r5.8.1
      { name = "ComplementaryReimagined_r5.8.1.zip";
        url  = "https://cdn.modrinth.com/data/HVnmMxH1/versions/yCCduG44/ComplementaryReimagined_r5.8.1.zip";
        hash = "sha512-a9lSFXVdJYElVs55DZdiIffWd9YxEuPk0+cLCKYu1BNI+jeS3TG75yDR5G/i1SXK209m5jWBGOH0qo4NEfJcOQ=="; }
      # rethinking-voxels         r0.1-beta9
      { name = "rethinking-voxels_r0.1-beta9.zip";
        url  = "https://cdn.modrinth.com/data/kmwfVOoi/versions/cpD4esk9/rethinking-voxels_r0.1-beta9.zip";
        hash = "sha512-HjL0HmflJ8PGAUlnegW2HG0wXkQIEuKau6dFuO0wSVR4DKSNWLg0xJg1eQvDxNOPN8iTxcvf6p7cB7cuHavSlg=="; }
      # photon-shader             v1.3b
      { name = "photon_v1.3b.zip";
        url  = "https://cdn.modrinth.com/data/lLqFfGNs/versions/gUv7fBPN/photon_v1.3b.zip";
        hash = "sha512-QLy6ycZW8pZfVD5LNc0GmHI7Lbi2dmLxtTwUIjz7731g1/vwF29z/K3Q0eGbpg2VHtd+nuzoyN99yk0r5jFTCQ=="; }
      # bliss-shader              2.1.2
      { name = "Bliss_v2.1.2_(Chocapic13_Shaders_edit).zip";
        url  = "https://cdn.modrinth.com/data/ZvMtQlho/versions/kC2Y8q1P/Bliss_v2.1.2_%28Chocapic13_Shaders_edit%29.zip";
        hash = "sha512-2vxgvkmA7ED0DtwPJiXLCXbzyc5e2GODFGoSBICCa7HecO9eOLfxQ3KU7U04xu88guvvCuTgC4zuFleIycGCgA=="; }
    ];

    resourcepacks = [
      # optimum-realism      3.9.0
      { name = "Optimum Realism R3.9.0 64x.zip";
        url  = "https://cdn.modrinth.com/data/jbhXFk8s/versions/Dr1zQHPD/Optimum%20Realism%20R3.9.0%2064x.zip";
        hash = "sha512-/TT9p8FFpROOzIL7YWttO1BJ1rvfis9uOXCKT1uwMgEjY61JJB33k4RWbaDIIp23kicdR8+wXvV2ereWbjhOpg=="; }
      # fresh-animations     1.10.4
      { name = "FreshAnimations_v1.10.4.zip";
        url  = "https://cdn.modrinth.com/data/50dA9Sha/versions/xN57JJts/FreshAnimations_v1.10.4.zip";
        hash = "sha512-QSWPm+oadz2CP5oBTQwIIG6eezObxTjhU4IR//KPrdBoeKg20pLLtjbtaCnNKAGlCTaK4+s61L7fQhkKDV96kA=="; }
      # prettyrealistic      0.43
      { name = "Pretty Realistic v0.43 [32x] Free.zip";
        url  = "https://cdn.modrinth.com/data/nDGgVA6Q/versions/K6tiMvm2/Pretty%20Realistic%20v0.43%20%5B32x%5D%20Free.zip";
        hash = "sha512-KUgf8UwOiQawrcnFJw1RF7V5VBnqHIQYePBCj+KWsFBKg/AF1DsgcYsocQcp1vAcQI5DXJTgzenVpRCV0E35nA=="; }
      # realistic-java-pack  3.4.1
      { name = "LOW_RealisticJAVApack_3.4.1.zip";
        url  = "https://cdn.modrinth.com/data/x1GlDcGQ/versions/Y45Pb7Hj/LOW_RealisticJAVApack_3.4.1.zip";
        hash = "sha512-EdSvVYMlKhxDD+M7gyINZ2gVxdYyQ3v1YrHkiSf+KNNArIMC/RiLF2bM/cgHR4uTpwj1jLEBVbMVdgiG3RnhWQ=="; }
    ];
  };

  installGroup = group: entries:
    ''
      mkdir -p "$out/${group}"
    '' + lib.concatMapStrings (e: ''
      cp ${fetch e} "$out/${group}/${e.name}"
    '') entries;
in
stdenvNoCC.mkDerivation {
  pname = "minecraft-realism-content";
  version = "1.21.8";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    ${lib.concatStrings (lib.mapAttrsToList installGroup sources)}
    runHook postInstall
  '';

  passthru = {
    inherit sources;
    minecraftVersion = "1.21.8";
    fabricLoaderVersion = "0.19.3";

    ## Seeded into options.txt / iris.properties by the module. Kept here so a
    ## version bump updates the filenames and the files that reference them in
    ## one place -- otherwise options.txt silently points at a pack that no
    ## longer exists and Minecraft drops it without saying why.
    defaults = {
      shaderPack = "ComplementaryUnbound_r5.8.1.zip";
      resourcePacks = [ "Optimum Realism R3.9.0 64x.zip" "FreshAnimations_v1.10.4.zip" ];
    };
  };

  meta = with lib; {
    description = "Pinned mods, shaderpacks and resourcepacks for the Realism Minecraft instance (Fabric 1.21.8)";
    platforms = platforms.linux;
  };
}
