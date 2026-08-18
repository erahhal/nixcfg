# Package config: allowUnfree, unstable/trunk channels, overlays
{ config, inputs, lib, system, ... }:
let
  ## genai-server's `ds4-flash` (DeepSeek-V4-Flash-0731) needs llama.cpp
  ## >= b10254: the arch landed in June, but the 0731 checkpoint's chat
  ## template and the DSML tool-call separator fix are commit 0ef6e55e
  ## (2026-08-04). Below that the model loads and ANSWERS — it just
  ## re-prefills the whole context on every agentic turn — so the failure
  ## reads as "slow model" rather than "wrong build". genai-server declares
  ## the floor as `serve.minLlamaCpp` and drops the model below it.
  ds4FlashFloor = "10254";

  ## genai-server's Qwen3.8 entries (`qwen38`, `qwen38-long`, `qwen38-uc`)
  ## need llama.cpp >= b10434, and unlike the floor above the failure is not
  ## "slow": on b10430 llama-server EXITS SILENTLY once a Qwen3.8 prompt
  ## passes ~90-100k tokens (llama.cpp #27090), which llama-swap surfaces as
  ## "upstream command exited prematurely" — the same string a VRAM overrun
  ## gives you. `qwen38-long` and `qwen38-uc` declare a 128k window, i.e.
  ## straight through that cliff, and `qwen38` sits at 96k, i.e. on it. This
  ## is the floor the override below actually has to clear; ds4FlashFloor is
  ## already met by anything recent.
  ##
  ## IT IS NOT OPTIONAL HERE ANY MORE. Since 2026-08-17 `qwen38` holds the
  ## `dense` alias and is what claude-logistikon defaults to, so below this
  ## floor genai-server drops it and the harness asks :4000 for a name
  ## nothing serves — a broken coding session rather than one missing model
  ## in a picker.
  qwen38Floor = "10434";

  trunkPkgs = import inputs.nixpkgs-trunk {
    inherit system;
    # Mirrors nixpkgs.config below. Written out rather than referencing
    # config.nixpkgs.config, which would be a module-eval cycle from here.
    # allowUnfree is load-bearing: genai-server builds this with
    # cudaSupport = true, which pulls unfree CUDA deps.
    config = { allowUnfree = true; allowBroken = true; };
  };
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      # obsidian, logseq, and bitwarden-desktop still pin electron_39 in
      # nixpkgs (default electron is now electron_41), and the bump marked
      # electron_39 EOL/insecure. nixpkgs pins it on purpose — those apps
      # aren't compatible with newer Electron yet — so allow it rather than
      # override (which would break them). Remove once they move to electron_41.
      packageOverrides = pkgs: {
        unstable = import inputs.nixpkgs-unstable {
          config = config.nixpkgs.config;
          inherit system;
        };
        trunk = import inputs.nixpkgs-trunk {
          config = config.nixpkgs.config;
          inherit system;
        };
        erahhal = import inputs.nixpkgs-erahhal {
          config = config.nixpkgs.config;
          inherit system;
        };
        # bottles = pkgs.bottles.override {
        #   removeWarningPopup = true;
        # };
      };
    };
  };

  nixpkgs.overlays = [
    # CachyOS kernels (provides pkgs.cachyosKernels.linuxPackages-cachyos-*).
    # Used by modules/hardware/dmemcg for the dmem cgroup VRAM-management patches.
    # Use `pinned` (not `default`) so the kernel is built against the exact
    # nixpkgs revision xddxdd's Hydra used -- otherwise the derivation hash
    # differs from what's in the attic.xuyh0120.win/lantian cache and the
    # kernel rebuilds locally.
    inputs.nix-cachyos-kernel.overlays.pinned

    # Always-fresh Claude Code. nixpkgs' claude-code lags Anthropic releases
    # by days/weeks; sadjow/claude-code-nix republishes within ~1h. This
    # overlay redefines pkgs.claude-code (a prebuilt native Bun binary built
    # against our nixpkgs via final.callPackage), transparently upgrading the
    # `claude-code` entry in modules/base-user. See the input in flake.nix.
    inputs.claude-code.overlays.default

    (final: prev: {
      # Fix gamescope 3.16.22 swapchain handling for Wayland compositors:
      # 1) vulkan_remake_swapchain() re-queries surface capabilities (stale
      #    caps from init cause vkCreateSwapchainKHR to fail on Wayland)
      # 2) Replace assert(bRet) with graceful error return
      # 3) Replace infinite acquire loops with bounded retry
      # (ValveSoftware/gamescope#1857). Remove once upstream fixes this.
      gamescope = prev.gamescope.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # 1) In vulkan_remake_swapchain: re-query surface caps + replace assert
          substituteInPlace src/rendervulkan.cpp \
            --replace-fail \
              '	bool bRet = vulkan_make_swapchain( pOutput );
	assert( bRet ); // Something has gone horribly wrong!
	return bRet;
}' \
              '	// Re-query surface capabilities (may have changed since init on Wayland)
	if ( GetBackend()->UsesVulkanSwapchain() )
	{
		auto result = g_device.vk.GetPhysicalDeviceSurfaceCapabilitiesKHR( g_device.physDev(), pOutput->surface, &pOutput->surfaceCaps );
		if ( result != VK_SUCCESS )
		{
			fprintf( stderr, "[gamescope] vulkan_remake_swapchain: failed to re-query surface caps\\n" );
			return false;
		}
		uint32_t formatCount = 0;
		result = g_device.vk.GetPhysicalDeviceSurfaceFormatsKHR( g_device.physDev(), pOutput->surface, &formatCount, nullptr );
		if ( result == VK_SUCCESS && formatCount != 0 )
		{
			pOutput->surfaceFormats.resize( formatCount );
			g_device.vk.GetPhysicalDeviceSurfaceFormatsKHR( g_device.physDev(), pOutput->surface, &formatCount, pOutput->surfaceFormats.data() );
		}
	}
	bool bRet = vulkan_make_swapchain( pOutput );
	if ( !bRet )
		fprintf( stderr, "[gamescope] vulkan_remake_swapchain: swapchain recreation failed\\n" );
	return bRet;
}

// Bounded retry for swapchain acquire (prevents infinite loop)
bool vulkan_remake_and_acquire( void )
{
	int attempts = 0;
	while ( !acquire_next_image() )
	{
		if ( ++attempts > 3 || !vulkan_remake_swapchain() )
			return false;
	}
	return true;
}'

          # 2) Replace infinite acquire loops with bounded retry
          substituteInPlace src/rendervulkan.cpp \
            --replace-fail \
              '	while ( !acquire_next_image() )
		vulkan_remake_swapchain();
}

gamescope::Rc<CVulkanTexture> vulkan_create_1d_lut' \
              '	vulkan_remake_and_acquire();
}

gamescope::Rc<CVulkanTexture> vulkan_create_1d_lut'

          # 3) Replace infinite acquire loop in vulkan_make_output
          substituteInPlace src/rendervulkan.cpp \
            --replace-fail \
              '		while ( !acquire_next_image() )
			vulkan_remake_swapchain();
	}
	else' \
              '		vulkan_remake_and_acquire();
	}
	else'

          # 4) Replace infinite acquire loop in steamcompmgr
          substituteInPlace src/steamcompmgr.cpp \
            --replace-fail \
              '			vulkan_remake_swapchain();

				while ( !acquire_next_image() )
					vulkan_remake_swapchain();' \
              '			vulkan_remake_swapchain();
				vulkan_remake_and_acquire();'

          # 5) Fix: set g_bFirstFrame=false before focus check in paint_all().
          # Without this, during Steam startup when no X11 window has focus,
          # paint_all() returns early and g_bFirstFrame stays true forever,
          # preventing the SDL window from ever being shown.
          substituteInPlace src/steamcompmgr.cpp \
            --replace-fail \
              '	if ( !pFocus )
		return;' \
              '	g_bFirstFrame = false;
	if ( !pFocus )
		return;'

          # 6) Add declaration to header
          substituteInPlace src/rendervulkan.hpp \
            --replace-fail \
              'bool vulkan_remake_swapchain( void );' \
              'bool vulkan_remake_swapchain( void );
bool vulkan_remake_and_acquire( void );'
        '';
      });

      jetbrains-toolbox = prev.jetbrains-toolbox.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [ prev.makeWrapper ];
        postInstall = old.postInstall or "" + ''
          wrapProgram "$out/bin/jetbrains-toolbox" \
            --add-flags "--graphics-api software"
        '';
      });

      ranger = prev.ranger.overrideAttrs (old: {
        imagePreviewSupport = true;
      });

      weechat = prev.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with prev.weechatScripts; [];
        };
      };

      # TEMPORARY: llama.cpp from trunk, for genai-server's ds4-flash. Same
      # shape as the langfuse pin below — fixed on master, not yet on
      # nixos-unstable (which as of 2026-08-06 still ships b10133 even after
      # a flake update; the bump missed this channel's branch point).
      #
      # TRUNK IS NO LONGER FAR ENOUGH, so this is trunk's DERIVATION with a
      # newer SOURCE pinned on top. genai-server's Qwen3.8 entries declare
      # serve.minLlamaCpp = b10434 and nothing in any channel is there yet:
      # nixos-unstable is b10133, this trunk pin is b10273, and even
      # nixpkgs master is only b10408. Bumping the trunk INPUT would not
      # help — it lands on b10408, still short — so the version and src
      # hash are set here instead. Upstream b10472 is 2026-08-17.
      #
      # WHY b10434 IS THE FLOOR: llama.cpp #27090 reports llama-server
      # exiting SILENTLY on Qwen3.8-27B past ~90-100k of prompt on b10430,
      # gone by b10434. Only four commits separate those tags and one is
      # `ggml : recurrent state rollback for ggml_ssm_scan` (#26623), which
      # is the attribution the reporter offers — marked "presumably" there
      # and worth treating as such, since the crash was plain prefill and
      # that commit is about draft-token state. Taking the whole tested
      # build rather than backporting one 25-file cross-backend commit is
      # the point: the floor is empirical (b10430 dies, b10434 does not)
      # even where the cause is not settled.
      #
      # This also brings `chat : pass reasoning_effort to template`, which
      # gives llama-server a native --reasoning-effort instead of the
      # --chat-template-kwargs route genai-server uses for Qwen3.8 today.
      #
      # OVERRIDING src MEANS OVERRIDING npmDepsHash: the derivation builds
      # the bundled web UI from tools/ui, and that lockfile changed between
      # b10273 and b10408. It did NOT change between b10408 and b10472
      # (verified byte-identical), so this is master's value.
      #
      # STILL SELF-RETIRING, now against the HIGHER of the two floors —
      # retiring at ds4-flash's b10254 would drop the Qwen3.8 pair without
      # anything saying so, which is the failure this warning exists to
      # prevent. When it fires, delete this binding and the trunkPkgs
      # import above; leaving it pins llama.cpp to a hand-set tag forever,
      # which is how a temporary override becomes a permanent one.
      llama-cpp = lib.warnIf
        (lib.versionAtLeast prev.llama-cpp.version qwen38Floor)
        ("nixcfg: nixos-unstable's llama-cpp is now b${prev.llama-cpp.version}"
          + " (>= b${qwen38Floor}, the highest floor genai-server declares),"
          + " so the nixpkgs-trunk override in"
          + " modules/system/overlays/default.nix is redundant. Remove the"
          + " llama-cpp binding and the trunkPkgs import.")
        (trunkPkgs.llama-cpp.overrideAttrs (finalAttrs: old: {
          version = "10472";
          src = trunkPkgs.fetchFromGitHub {
            owner = "ggml-org";
            repo = "llama.cpp";
            tag = "b${finalAttrs.version}";
            hash = "sha256-re0WlafJUDZOPNfIq2ECRSctdrDFVc0fXb5iSd7gDR8=";
            leaveDotGit = true;
            postFetch = ''
              git -C "$out" rev-parse --short HEAD > $out/COMMIT
              find "$out" -name .git -print0 | xargs -0 rm -rf
            '';
          };
          npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
        }));

      # TEMPORARY: nixos-unstable moved glaze to 8.0.0, but the hyprland it
      # still ships (0.56.1) does `find_package(glaze 7...<8 QUIET)` and, when
      # that finds nothing, falls back to a FetchContent git clone of
      # glaze v7.2.0 — which the build sandbox has no network for, so
      # configure dies with "could not find git for clone of glaze". Hand it
      # the 7.x it actually asks for. Upstream dropped the version bound after
      # the 0.56.1 tag (main is now plain `find_package(glaze QUIET)`), so the
      # next hyprland bump in nixpkgs makes this unnecessary.
      #
      # SELF-RETIRING like the llama-cpp pin above: warnIf fires at eval time
      # once nixpkgs' hyprland moves past 0.56.1. Hosts with
      # hostParams.desktop.useHyprlandFlake = true replace pkgs.hyprland from
      # their own overlay and never see this one.
      hyprland = lib.warnIf
        (lib.versionOlder "0.56.1" prev.hyprland.version)
        ("nixcfg: nixpkgs' hyprland is now ${prev.hyprland.version} (> 0.56.1),"
          + " which builds against glaze 8, so the glaze 7.x override in"
          + " modules/system/overlays/default.nix is redundant. Remove the"
          + " hyprland binding.")
        (prev.hyprland.override {
          glaze = prev.glaze.overrideAttrs (old: rec {
            version = "7.2.0";
            src = prev.fetchFromGitHub {
              owner = "stephenberry";
              repo = "glaze";
              tag = "v${version}";
              hash = "sha256-f3NVRi3SXKo42hn0WCw7JsOK3EkdOVJIcuzhPorKjFY=";
            };
          });
        });

      # langfuse 4.0.2 declares wrapt<2.0 but nixpkgs now ships wrapt 2.2.2,
      # which fails the runtime-deps check and breaks litellm. Fixed on nixpkgs
      # master (45368b0, 2026-07-23) but not yet on nixos-unstable. Remove once
      # a flake update pulls a nixpkgs rev containing that fix.
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          langfuse = pyprev.langfuse.overridePythonAttrs (old: {
            pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "wrapt" ];
          });
        })
      ];
    })
  ];
}
