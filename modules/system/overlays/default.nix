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
  ## floor genai-server drops it and the harness asks the bridge for a name
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

      # TEMPORARY, AND IT NOW OUTLIVES THE REASON IT WAS WRITTEN FOR.
      # genai-server's qwen38-125b-a6b (Qwen3.8-Flash-Next) loads as
      # `qwen4exp`, and when this binding was added that architecture
      # existed in NO released llama.cpp: support was ggml-org#27742, open
      # with master at b10636. IT MERGED on 2026-08-27 as 6c84c7d5, and
      # b10660 is the first release carrying it — checked rather than
      # inferred: b10659 is exactly one commit behind that merge and b10660
      # is identical to it.
      #
      # SO THE PIN IS STILL HERE, FOR A DIFFERENT REASON, and saying which
      # is the whole job of this comment. What is NOT upstream is MTP: the
      # NextN multi-token-prediction draft head, which unsloth ships for
      # this model as its own GGUF and which llama.cpp can only be handed
      # as `-md <head> --spec-type draft-mtp`. THREE competing PRs carry it
      # as of 2026-09-09 and none has merged — #27836 (rmonsurate), #28243
      # (danielhanchen, this branch), #28610 (noonr48) — so the question
      # this pin answers has not changed, only the branch under it.
      #
      # THE BASE MOVED AGAIN, 2026-09-09, and the reason is one commit.
      # Merge base 0f3a71be (b10760) -> 95ef7fc1 (b10791: checked against
      # the tag ref, not counted from a date), head 2857e511 -> d1a9235
      # (2026-09-05). Four of the five commits between are #28243's review
      # rework — `mtp_shared_embd` metadata, a draft-only export rejection,
      # shared-tensor borrowing moved onto `ctx_other`. The fifth is a
      # CORRECTNESS fix for this model: `speculative : only gemma4-assistant
      # shares the target KV cache` — a qwen4exp draft that borrows the
      # target's embeddings sets `ctx_other` but keeps its own memory, so it
      # must be caught up and rolled back like any other draft. The build
      # this replaces drafted without that, which is the half of the pair
      # that runs MTP.
      #
      # THE GDN FIX IS CARRIED AS A PATCH, NOT WAITED FOR. ggml-org#28068
      # (5fdfa628, merged 2026-09-06, first released as b10829) corrects
      # every GDN q/k normalization from `x / max(sqrt(sum(x*x)), eps)` to
      # the reference `x * rsqrt(sum(x*x) + eps)` — the clamp never engages
      # at these magnitudes, so llama.cpp was normalizing with no epsilon
      # at all. It lands on qwen4exp AND on qwen35/qwen35moe/qwen3next,
      # i.e. on the fleet engine below as well; the measured effect is
      # small (mean KL 0.001750 against 0.001769, 98.4% top-1 match on
      # Qwen3.8-27B Q4_K_M) and it needs no re-quantized GGUF. It is a
      # patch rather than a rebase because b10829 is three days AFTER this
      # branch's base and only its author can move the branch.
      #
      # IT BRINGS `--lazy-mode`, WHICH DEFAULTS TO AUTO — a behaviour change
      # nothing announces. b10791 reads arch-marked tensors larger than 4GiB
      # on demand rather than resident, and qwen4exp's n-gram/PLE table is
      # exactly that tensor; b10760 has no such flag (checked against the
      # deployed binary's strings, not the changelog), so every VRAM, tok/s
      # and prefill number in that catalog was measured without it.
      # genai-server therefore pins `--lazy-mode off` on both entries, so
      # this bump stays one variable. `on` is a measurement to take next —
      # #28136 (`on-direct`, still open) reports cold prefill 167 -> 621
      # tok/s on a 5090 with a 4-6% warm penalty, which is this box's
      # cold-cache curve with a fix attached.
      #
      # version MUST STAY NUMERIC: it is passed as -DLLAMA_BUILD_NUMBER,
      # which is an int in C, so "10791-mtp" would fail to compile rather
      # than merely read oddly. b10791 is the master this branch sits on;
      # the branch is what the attribute name records, and the patch above
      # means the binary is NOT any released build — b10791 plus one commit
      # from b10829.
      #
      # NO cudaSupport HERE. genai-server applies its own
      # `hardware.accelerator` to whatever it is handed, so setting a
      # backend here would risk two engines on one box disagreeing about
      # it — invisible until one of them fails.
      #
      # npmDepsHash is the binding's above: tools/ui/package-lock.json is
      # byte-identical from b10472 through this commit (585457 bytes,
      # sha256 03379c8e…, re-compared at d1a9235 on 2026-09-09).
      #
      # HOW THIS RETIRES, AND WHY THAT QUESTION CHANGED UNDER IT.
      # genai-server greps the HOST's llama.cpp on every rebuild and fails
      # the build once the pin is redundant, naming the edits; the catalog
      # entry declares what to look for. Until 2026-08-27 that was
      # `serve.engineArch = "qwen4exp"` alone — and today that string would
      # fire WRONGLY: nixpkgs crossing b10660 would demand this attribute
      # be deleted while MTP is still only on this branch. So the entry now
      # also declares `serve.engineFeature` and the probe wants BOTH before
      # it calls the pin redundant. A pin retires when the host engine can
      # do everything it was pinned FOR; that was always the intent, and
      # was only accidentally the same question as the architecture.
      #
      # THE FEATURE STRING IS PER-ENTRY, AND THIS COMMENT NAMED A DEAD ONE
      # TWICE. It said `nextn_shared_target_tensors` — the metadata key the
      # pre-review branch used, which review replaced with `ctx_other`
      # borrowing — long after the catalog had moved to the draft head's
      # own assert text. Read the entry, not this line: qwen38-125b-a6b
      # declares `QWEN4EXP MTP`, which is what THIS build is pinned for,
      # and qwen38-125b-a6b-max declares `QWEN4EXP_QSA_GATHER` because it
      # runs no drafter and takes `llama-cpp-qwen4exp-next` below instead.
      llama-cpp-qwen4exp = trunkPkgs.llama-cpp.overrideAttrs (finalAttrs: old: {
        pname = "llama-cpp-qwen4exp";
        version = "10791";
        src = trunkPkgs.fetchFromGitHub {
          owner = "danielhanchen";
          repo = "llama.cpp";
          rev = "d1a92352cbd417fd840b4e765c0b82f5fe3d1d89";
          hash = "sha256-ar7X+tURfutuAVNRvlc9JxgzhUXtM7PMANeosuwnAKo=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > $out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        patches = (old.patches or []) ++ [ ./patches/llamacpp-28068-gdn-l2norm-rsqrt.patch ];
        npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
      });

      # A MEASUREMENT, NOT A DEPLOYMENT, and the distinction is the reason
      # it is a second attribute rather than one more patch above.
      # ggml-org#28213 ("qwen4exp : gather-based sparse attention for QSA
      # decode") is OPEN: the indexer already picks the top 2048 cells and
      # the decode then runs attention across the WHOLE context with a
      # mask, so the PR gathers those cells into a compact buffer and runs
      # dense attention over them instead. Reported on 2xA6000 at IQ4_XS
      # with a q8_0 cache: 130k 15.7 -> 23.6 tok/s (+50%), 62k +19%, 31k
      # +6% — which is aimed straight at the one number this box complains
      # about, generation nearly halving as the window fills (18.6 -> 9.9
      # tok/s at 254566 tokens on qwen38-125b-a6b-max).
      #
      # MEASURED 2026-09-09 AND PROMOTED — logistikon points both halves at
      # this one. A/B on a quiet box, same script, nCpuMoe 34, q8_0 KV,
      # drafter off, identical prompts:
      #                  123k gen   253k gen   123k pp   253k pp   peak VRAM
      #   b10791          26.31      21.10      822.5     669.1     25496
      #   + #28213        30.13      25.70      824.1     668.9     25496
      # +14.5% and +21.8% of generation, prefill and VRAM unmoved — which
      # is the shape a decode-only patch should have, and is why the two
      # unchanged columns are worth as much as the two that moved. Less
      # than the PR's +50% on 2xA6000, as expected: generation here is
      # bound by streaming experts out of host RAM, not by GPU attention.
      #
      # AND IT PRODUCES THE SAME TOKENS, which is the half that decides
      # whether an UNMERGED patch may serve people. Greedy, seeded,
      # byte-compared against the base engine: a 2022-character reasoning
      # trace plus answer, identical; a needle planted 35% into a 120k
      # haystack, recalled identically. A gather over the indexer's top-k
      # that dropped a cell would show up as exactly that recall failing.
      #
      # DELETE THIS ATTRIBUTE WHEN #28213 MERGES, and move the two
      # `enginePackage` lines back to `llama-cpp-qwen4exp` — carrying a
      # patch upstream already has is how a temporary pin becomes
      # permanent.
      llama-cpp-qwen4exp-qsa = final.llama-cpp-qwen4exp.overrideAttrs (old: {
        pname = "llama-cpp-qwen4exp-qsa";
        patches = (old.patches or []) ++ [ ./patches/llamacpp-28213-qsa-gather-decode.patch ];
      });

      # THE SAME PATCH ON MASTER, FOR THE HALF THAT DOES NOT DRAFT — and
      # the reason it is a fourth attribute is that `-max` has been paying
      # for an MTP branch it never uses.
      #
      # `qwen38-125b-a6b-max` carries NO `serve.draft`: the MTP head is
      # measured as a 10% LOSS on that half (4.16 tok/s without, 3.75 with,
      # matched nCpuMoe 44) because a k+1 verification batch streams k+1
      # times the expert weights and 104GB does not fit in 123GB of RAM.
      # Confirmed against the running process rather than the catalog:
      # `-md`, `--spec-type` and `draft` appear nowhere on its command
      # line. So everything the MTP branch exists for is dead weight there,
      # and the branch's base is what it costs — b10791, 2026-09-05.
      #
      # THE BRANCH HAS STOPPED MOVING AND MASTER HAS NOT. #28243's head is
      # still d1a9235 (compared against the branch ref: identical, 0 ahead
      # 0 behind), its last commit is 2026-09-04, a reviewer asked for a
      # rebase on 2026-09-15 because #28896 now conflicts, and on
      # 2026-09-17 somebody asked whether it is still alive. Master
      # meanwhile is b11028 and has taken FOUR qwen4exp changes this half
      # is not getting:
      #   #28330  2026-09-10  the indexer KV cache stops allocating a V
      #                       half it never reads. Issue #28296 measures
      #                       this exact model at 12 indexed layers: 4096
      #                       cells is K 12MiB / V 24MiB, so at -c 262144
      #                       the wasted V is ~1536MiB at f16 and ~800MiB
      #                       at the q8_0 this entry ships.
      #   #28896  2026-09-14  rms_norm + mul fusion, author measures +3% PP
      #   #28901  2026-09-16  native hc ops (this model sets
      #                       hyper_connection.count = 4)
      #   #28739  2026-09-11  0-sized ids tensor when offloading experts,
      #                       which is the --n-cpu-moe path this box runs
      # The first of those is the one that matters: this entry's whole
      # failure history is headroom, it runs at 3955MiB free, and an
      # offload layer here is ~1500MiB.
      #
      # WHAT IS AND IS NOT CARRIED, checked rather than assumed:
      #   * #28213 STAYS — still open, still the reason for a pin at all.
      #     Dry-run against master: applies clean, all hunks, offsets only.
      #     The reviewer warning on that PR (it would build-break against
      #     #27970's `build_attn_mha` without a git conflict) does NOT
      #     apply to the copy in this tree — it already passes the `n_topk`
      #     argument, which is why it builds on b10791, and master's own
      #     call sites have the same 10-argument shape.
      #   * #28068 IS DROPPED — it merged 2026-09-06 and released as
      #     b10829, and master's qwen4exp.cpp now calls the shared
      #     `build_gdn_l2_norm` helper it introduced. Carrying it here
      #     would be applying a patch upstream already has.
      #   * #28671 IS CARRIED AND IS WORTH NOTHING HERE — radix-select
      #     TOP_K for the CUB fallback, added 2026-09-18 on a good
      #     prediction and measured flat the same day: 23.56 tok/s at
      #     253344 tokens against a control of 23.68, where the PR reports
      #     +13-18% on this same model and quant. It is still applied
      #     because removing it costs a 40-minute recompile and it does no
      #     harm, but DELETE IT at the next engine change rather than
      #     inheriting it — an unmerged patch that buys nothing is the
      #     purest form of the permanent-temporary pin. The patch header
      #     carries the numbers and the one test that would distinguish
      #     "not engaging" from "engaging and irrelevant".
      #
      #     READ THAT BEFORE TRYING #28699 OR ANY OTHER GPU-SIDE qwen4exp
      #     WORK. At nCpuMoe 38 this entry streams 38 of 48 MoE layers out
      #     of host RAM per token, and the evidence so far is that GPU
      #     time is not its critical path — which would make every
      #     optimisation of that kind a null result here, however well it
      #     measures on a card that holds the whole model.
      #
      # npmDepsHash is the binding's above and that is CHECKED, not
      # inherited: tools/ui/package-lock.json is byte-identical at b11028
      # to the pinned branch and to b10472 — 585457 bytes, sha256
      # 03379c8e…, compared 2026-09-17.
      #
      # SAME EXPIRY, DIFFERENT FEATURE, and the catalog says which: this
      # pin is for the gather and not for MTP, so
      # `qwen38-125b-a6b-max`'s `serve.engineFeature` is the gather's own
      # kill-switch string rather than `QWEN4EXP MTP`. Setting one without
      # the other fails the build, which is the retirement probe doing its
      # job — a pin whose declared reason is not the reason it is here has
      # no expiry at all. Delete this attribute when #28213 merges.
      llama-cpp-qwen4exp-next = trunkPkgs.llama-cpp.overrideAttrs (finalAttrs: old: {
        pname = "llama-cpp-qwen4exp-next";
        version = "11028";
        src = trunkPkgs.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          tag = "b${finalAttrs.version}";
          hash = "sha256-ORc2elp1FpSwk2Givmg0eUtOpUJq/Ar/dVKxGqEUacU=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > $out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        patches = (old.patches or []) ++ [
          ./patches/llamacpp-28213-qsa-gather-decode.patch
          ./patches/llamacpp-28671-cuda-radix-topk.patch
        ];
        # THE REPORTED BUILD NUMBER DOES NOT FOLLOW THE PIN, and every
        # llama-cpp override in this file has the bug — this is just the
        # one where nixpkgs had moved far enough to make it visible.
        # nixpkgs passes `-DLLAMA_BUILD_NUMBER`/`-DLLAMA_BUILD_COMMIT`
        # from ITS OWN version and rev, and neither follows
        # `finalAttrs.version` or `src.rev` through `overrideAttrs`. So
        # this attribute fetched b11028 (checked: the source's COMMIT file
        # reads 972d231) and the binary introduced itself as
        # "build 10809, commit 5266f24" — nixpkgs-trunk's llama-cpp, not
        # ours. `llama-cpp` and `llama-cpp-qwen4exp` above currently read
        # correctly only because they were built while trunk still sat
        # near their pins; they will start lying the same way on the next
        # trunk bump.
        #
        # Nothing functional depended on it — genai-server's retirement
        # probe greps arch and feature STRINGS, and `belowLlamaCppFloor`
        # exempts a model carrying its own engine — but a binary that
        # misreports itself is exactly the drift the pin comments exist to
        # prevent, and it cost half an hour of reading the wrong thing.
        # Appended so it wins: CMake takes the last -D of a repeated name.
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DLLAMA_BUILD_NUMBER:STRING=${finalAttrs.version}"
          "-DLLAMA_BUILD_COMMIT:STRING=972d231"
        ];
        npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
      });

      # TEMPORARY, AND A THIRD ENGINE RATHER THAN A SECOND. genai-server's
      # glm53-320b-a18b (GLM-5.3-Flash) loads as `glm5next`, which no
      # released llama.cpp knows: support is ggml-org/llama.cpp#27752, open
      # as of 2026-08-27. The qwen4exp binding above does NOT cover it —
      # checked, not assumed: that branch 404s on the glm5next sources and
      # this one 404s on src/models/qwen4exp.cpp. Two architectures, two
      # branches, two builds, and `serve.enginePackage` is per-model so a
      # host can have both instead of choosing.
      #
      # UNSLOTH'S BRANCH, NOT THE PR HEAD, and they have diverged: the PR
      # lives on a different fork (eauchs:glm5next/add-glm-5.3-flash) and
      # this branch is 30 commits ahead of it and 5 behind, with 50 files
      # differing. What decides it is `conversion/glm5next.py` — the
      # converter that PRODUCED the GGUF this box downloads lives on THIS
      # branch, so pinning the PR head risks a loader that disagrees with
      # the file. Revisit when the PR merges; the merged code is what the
      # entry's minLlamaCpp floor is waiting for.
      #
      # version 10638: both branches share merge base 5e6a37cb with
      # ggml-org master (2026-08-26 16:02Z), which sits between b10636 and
      # b10638. Numeric because it becomes -DLLAMA_BUILD_NUMBER, an int in
      # C — "10638-glm5next" would fail to compile rather than read oddly.
      #
      # npmDepsHash is the binding's above: tools/ui/package-lock.json is
      # byte-identical between b10472 and this commit (585457 bytes,
      # compared 2026-08-27).
      #
      # SAME EXPIRY AS THE OTHER PIN: the entry declares
      # serve.engineArch = "glm5next", genai-server greps this host's own
      # llama.cpp for that id on every rebuild, and the build fails once it
      # is there — so this attribute and the logistikon line using it die
      # together on the first rebuild after nixpkgs catches up.
      llama-cpp-glm5next = trunkPkgs.llama-cpp.overrideAttrs (finalAttrs: old: {
        pname = "llama-cpp-glm5next";
        version = "10638";
        src = trunkPkgs.fetchFromGitHub {
          owner = "unslothai";
          repo = "llama.cpp";
          rev = "2e0e57f1008053bae4902a772da85e3eb99d4aff";
          hash = "sha256-eukvUH7nnZXViH8D4vh6hNrVFbJa36/qosBMnEEQ9oE=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > $out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
      });

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
