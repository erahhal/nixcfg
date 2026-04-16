# Package config: allowUnfree, unstable/trunk channels, overlays
{ config, inputs, system, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
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
        bottles = pkgs.bottles.override {
          removeWarningPopup = true;
        };
      };
    };
  };

  nixpkgs.overlays = [
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

          # 6) Fix --force-grab-cursor not actually forcing.
          # The compositor loop calls SetRelativeMouseMode(false) when cursor
          # state changes, overriding the init-time force. Make the setter
          # respect g_bForceRelativeMouse. (gamescope#1711)
          substituteInPlace src/Backends/SDLBackend.cpp \
            --replace-fail \
              '	void CSDLBackend::SetRelativeMouseMode( bool bRelative )
	{
		m_bApplicationGrabbed = bRelative;' \
              '	void CSDLBackend::SetRelativeMouseMode( bool bRelative )
	{
		if ( g_bForceRelativeMouse )
			bRelative = true;
		m_bApplicationGrabbed = bRelative;'

          # 7) Add declaration to header
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
