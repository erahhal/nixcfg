# Gamescope Upstream Bug Fixes — SDL Nested Backend on Wayland

**Gamescope version:** 3.16.22
**Issue tracker:** https://github.com/ValveSoftware/gamescope/issues
**Environment:** NixOS, niri compositor, AMD Radeon 780M (RADV PHOENIX), 5120x2160 display
**Affected mode:** Nested (`--backend sdl`) with `--steam --force-grab-cursor`

These three bugs were found through source-level debugging while running gamescope nested inside the niri Wayland compositor. All three are in the upstream gamescope source and affect any Wayland compositor in nested mode. They are independent fixes.

---

## Bug 1: `vulkan_remake_swapchain()` uses stale surface capabilities

**Related issue:** https://github.com/ValveSoftware/gamescope/issues/1857

### Problem

`vulkan_remake_swapchain()` (rendervulkan.cpp:3244) destroys the old swapchain and calls `vulkan_make_swapchain()` to create a new one, but it **never re-queries Vulkan surface capabilities**. The `surfaceCaps`, `surfaceFormats`, and `presentModes` used are stale values from `vulkan_make_output()` (rendervulkan.cpp:3363), which were queried at initialization time when the SDL window was still hidden (`SDL_WINDOW_HIDDEN`).

On Wayland compositors, surface capabilities change when the window transitions from hidden to visible, or when it is resized or fullscreened. Using stale capabilities (especially `minImageExtent`/`maxImageExtent`) causes `vkCreateSwapchainKHR` to fail.

Additionally, `vulkan_remake_swapchain()` uses `assert(bRet)` which crashes gamescope entirely on failure. The callers use `while (!acquire_next_image()) vulkan_remake_swapchain();` with no bail-out condition, creating an infinite busy loop when the swapchain persistently fails (prior to the assert, or after changing it to a return-false).

Note the contrast with `vulkan_make_output()` (rendervulkan.cpp:3363-3418), which correctly queries `GetPhysicalDeviceSurfaceCapabilitiesKHR`, `GetPhysicalDeviceSurfaceFormatsKHR`, and `GetPhysicalDeviceSurfacePresentModesKHR` before calling `vulkan_make_swapchain()`.

### Symptoms

- Gamescope spams "Creating Gamescope nested swapchain with format 64 and colorspace 0" dozens of times
- Then crashes with `assert(bRet)` in `vulkan_remake_swapchain()`
- Or (with assert removed) enters an infinite CPU-burning loop with no visible output
- Intermittent — depends on timing of window state transitions relative to swapchain recreation

### Fix

Three changes:

**a) Re-query surface capabilities in `vulkan_remake_swapchain()` before creating the swapchain:**

```diff
 bool vulkan_remake_swapchain( void )
 {
     std::unique_lock lock(present_wait_lock);
     g_currentPresentWaitId = 0;
     g_currentPresentWaitId.notify_all();

     VulkanOutput_t *pOutput = &g_output;
     g_device.waitIdle();
     g_device.vk.QueueWaitIdle( g_device.queue() );

     pOutput->outputImages.clear();

     g_device.vk.DestroySwapchainKHR( g_device.device(), pOutput->swapChain, nullptr );

     // Delete screenshot image to be remade if needed
     for (auto& pScreenshotImage : pOutput->pScreenshotImages)
         pScreenshotImage = nullptr;

+    // Re-query surface capabilities — they may have changed since init
+    // (e.g. window shown, resized, or fullscreened on a Wayland compositor)
+    if ( GetBackend()->UsesVulkanSwapchain() )
+    {
+        auto result = g_device.vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(
+            g_device.physDev(), pOutput->surface, &pOutput->surfaceCaps );
+        if ( result != VK_SUCCESS )
+            return false;
+
+        uint32_t formatCount = 0;
+        result = g_device.vk.GetPhysicalDeviceSurfaceFormatsKHR(
+            g_device.physDev(), pOutput->surface, &formatCount, nullptr );
+        if ( result == VK_SUCCESS && formatCount != 0 )
+        {
+            pOutput->surfaceFormats.resize( formatCount );
+            g_device.vk.GetPhysicalDeviceSurfaceFormatsKHR(
+                g_device.physDev(), pOutput->surface,
+                &formatCount, pOutput->surfaceFormats.data() );
+        }
+    }
+
     bool bRet = vulkan_make_swapchain( pOutput );
-    assert( bRet ); // Something has gone horribly wrong!
+    if ( !bRet )
+        fprintf( stderr, "[gamescope] vulkan_remake_swapchain: swapchain recreation failed\n" );
     return bRet;
 }
```

**b) Replace infinite acquire loops with a bounded retry helper:**

```diff
+bool vulkan_remake_and_acquire( void )
+{
+    int attempts = 0;
+    while ( !acquire_next_image() )
+    {
+        if ( ++attempts > 3 || !vulkan_remake_swapchain() )
+            return false;
+    }
+    return true;
+}
```

Replace all three `while (!acquire_next_image()) vulkan_remake_swapchain();` call sites (in `vulkan_present_to_window()`, `vulkan_make_output()`, and `steamcompmgr.cpp` main loop) with `vulkan_remake_and_acquire()`.

---

## Bug 2: SDL window never shown in nested mode (`g_bFirstFrame` stuck true)

**No existing issue.** This is a newly identified bug.

### Problem

In `paint_all()` (steamcompmgr.cpp:2474), the first thing checked is:

```cpp
if ( !pFocus )
    return;
```

This returns **before** `g_bFirstFrame = false` (steamcompmgr.cpp:2748). In the SDL backend's visibility handler (SDLBackend.cpp:871), the window visibility in steam mode is:

```cpp
if ( steamMode )
    bVisible |= !g_bFirstFrame;
```

So the SDL window is only shown when `g_bFirstFrame` becomes false, which only happens when `paint_all()` executes past the focus check. But during Steam's startup — particularly during its self-restart phase (`reaping pid: XX -- steam`) — there is a gap where no X11 window exists and `pFocus` is null. During this gap, `paint_all()` returns early on every call, `g_bFirstFrame` stays true forever, and the SDL window is never shown.

### Symptoms

- Gamescope starts, Steam starts inside it (tray icon appears, Steam logs show normal startup)
- But the gamescope SDL window never appears in the parent compositor
- `hasRepaint` keeps firing (gamescope tries to paint) but `g_bFirstFrame` stays true
- Killing gamescope and relaunching sometimes works (timing-dependent — if Steam creates its X11 window before the first `paint_all()` call, it works)

### Debug trace evidence

```
[GS-DEBUG] hasRepaint=true (#1)
[GS-DEBUG] hasRepaint=true (#2)
[GS-DEBUG] hasRepaint=true (#3)
[GS-DEBUG] VIS bVis=0 shown=0 steam=1 1stF=1   ← g_bFirstFrame stuck at 1
[GS-DEBUG] VIS bVis=0 shown=0 steam=1 1stF=1
[GS-DEBUG] VIS bVis=0 shown=0 steam=1 1stF=1
... (repeats forever, FIRST_PAINT never appears)
```

### Fix

Set `g_bFirstFrame = false` before the focus check in `paint_all()`:

```diff
 static void
 paint_all( ... )
 {
+    g_bFirstFrame = false;
     if ( !pFocus )
         return;
```

This allows the SDL window to become visible after the first paint attempt, even if no X11 window has focus yet. The window will briefly show a blank frame until Steam's UI window appears, which is acceptable — the alternative is the window never appearing at all.

---

## Bug 3: `--force-grab-cursor` doesn't actually force cursor grab

**Related issue:** https://github.com/ValveSoftware/gamescope/issues/1711

### Problem

The `--force-grab-cursor` flag (`g_bForceRelativeMouse`) is documented as "always use relative mouse mode instead of flipping dependent on cursor visibility." However, it only sets `SDL_SetRelativeMouseMode(SDL_TRUE)` once at init (SDLBackend.cpp:628-631).

The compositor main loop at steamcompmgr.cpp:8829-8831 calls `SetRelativeMouseMode(bRelativeMouseMode)` every frame, where:

```cpp
const bool bRelativeMouseMode = bImageEmpty && bHasPointerConstraint && !bExcludedAppId;
pPaintFocus->GetNestedHints()->SetRelativeMouseMode( bRelativeMouseMode );
```

This overrides the init-time setting whenever cursor state changes (e.g., Steam overlay appearing, game switching between menu/gameplay, pointer constraints changing). The `CSDLBackend::SetRelativeMouseMode()` setter (SDLBackend.cpp:529) blindly accepts whatever value is passed without checking `g_bForceRelativeMouse`.

### Symptoms

- Mouse cursor hits the screen edge and stops turning in FPS games
- Can only rotate the camera a limited amount before the mouse "sticks"
- Intermittent — depends on game's cursor state and pointer constraint behavior
- Widely reported on niri, sway, and other Wayland compositors in nested mode

### Fix

Make the setter respect `g_bForceRelativeMouse`:

```diff
 void CSDLBackend::SetRelativeMouseMode( bool bRelative )
 {
+    if ( g_bForceRelativeMouse )
+        bRelative = true;
     m_bApplicationGrabbed = bRelative;
     PushUserEvent( GAMESCOPE_SDL_EVENT_GRAB );
 }
```

This is a one-line fix that makes `--force-grab-cursor` actually do what its name and documentation say — always use relative mouse mode, regardless of what the compositor loop requests.

---

## Summary

| Bug | File | Impact | Type |
|-----|------|--------|------|
| Stale surface caps in swapchain remake | rendervulkan.cpp | Crash or infinite loop on Wayland | Clear bug fix |
| `g_bFirstFrame` stuck true | steamcompmgr.cpp | SDL window never appears | Design fix for nested mode |
| `--force-grab-cursor` not enforced | SDLBackend.cpp | Mouse hits screen edge in games | Clear bug fix |

All three are specific to nested mode (`--backend sdl` or `--backend wayland` on a Wayland compositor). They do not affect DRM session mode (Steam Deck).
