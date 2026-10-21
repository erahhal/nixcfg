# Package config: allowUnfree, unstable/trunk channels, overlays
{ config, inputs, lib, system, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;

      # NO allowBroken HERE, AND IT MUST STAY THAT WAY. It is not a harmless
      # "let me build broken things" switch any more: since the 2026-10-01
      # nixpkgs bump, meta.broken is computed from the new problems framework
      # (check-meta.nix: `broken = hasProblemKind "broken"`) and the broken
      # problem's generator opens with `if allowBroken then attrs: false`
      # (problems.nix). Setting it therefore makes meta.broken read FALSE on
      # EVERY package in the tree -- not just for us, but for the ~20 places
      # in nixpkgs whose own Nix code filters on it: gimp/wrapper.nix and
      # inkscape/with-extensions.nix dropping incompatible plugins,
      # matrix-synapse's optional deps, tree-sitter grammars, nushell and
      # maubot plugins, `doCheck = !valgrind.meta.broken`. With it on,
      # gimp-with-plugins pulled all seven GIMP-2-only plugins into a GIMP 3
      # build and died compiling farbfeld.
      #
      # Nothing here needs it. The `broken` stub helper (lib/broken.nix, used
      # as `(broken vllm)` in modules/hosts/nflx-erahhal-p16) builds its
      # stubs from its OWN pkgs instance that sets allowBroken itself
      # (lib/shared.nix, flake-modules/home.nix) -- and nixpkgs only checks
      # validity in the instance that CREATES a derivation, never in the
      # consumer, so those stubs pass through this one untouched. Verified.
      #
      # If a package here is ever genuinely marked broken upstream, eval
      # fails naming it; wrap it as `(broken thatPackage)` or set
      # `problems.handlers.<pkg>.broken = "warn"` for that one package, which
      # leaves meta.broken intact. Do not reach for the global flag.
      #
      # (An electron_39 note used to sit here. It documented
      # `permittedInsecurePackages = [ "electron-39.8.10" ]`, added
      # 2026-06-03 and removed 2026-06-13 in "fixed issues with slow
      # builds"; the comment outlived the setting. logseq is not installed
      # anywhere in this repo, and obsidian and bitwarden-desktop both
      # evaluate with no flag at all. Note electron_39 is marked INSECURE,
      # not broken, so allowBroken never covered it regardless.)
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
    })
  ];
}
