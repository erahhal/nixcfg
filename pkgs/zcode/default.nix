# ZCode, Z.ai's coding agent: the terminal CLI only (apps/zcode-cli), built
# from source. Upstream publishes no npm package or binary for it — the CLI
# ships inside the desktop app — but the repository is Apache-2.0 and the
# CLI builds to one esbuild bundle (dist/zcode.cjs) that runs on plain Node.
#
# The local-fleet configuration is NOT here; this is the bare tool, and
# `zcode-local` in modules/programs/ai-coding wraps it.
{ lib
, stdenv
, fetchFromGitHub
, nodejs_24
, pnpm_10
, fetchPnpmDeps
, pnpmConfigHook
, makeWrapper
, ripgrep
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zcode";
  # apps/zcode-cli's own version; the repository root (3.18.2) is the
  # desktop app's.
  version = "0.17.1-unstable-2026-11-13";

  src = fetchFromGitHub {
    owner = "zai-org";
    repo = "ZCode";
    rev = "fec975905a2abd4c07e35c40d51fa097a2258ec9";
    hash = "sha256-wkpPM93M30Bemd13ezLBffRPOQUGJSLD6V59v2BrxoM=";
  };

  # The CLI and everything it builds from, plus apps/zcode-cli itself for
  # the esbuild/tsx its build scripts import. Not the desktop app, the web
  # client or the server, which are most of the monorepo.
  pnpmWorkspaces = [ "@zcode/cli..." "zcode-cli" ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src pnpmWorkspaces;
    pnpm = pnpm_10;
    fetcherVersion = 5;
    hash = "sha256-C1K79bwZZPbg89noEebUZGKmswifyospN8QsgyuCIZE=";
  };

  # The repository's .npmrc asks for `node-linker=hoisted`, and that is the
  # one layout that failed here: one sandboxed install in three died on
  # "ENOENT: rename node_modules/vite/node_modules/_tmp_..." — pnpm racing
  # itself over a nested directory — while every run outside the sandbox
  # passed, which is the shape of a race and not of a bad lockfile. The
  # isolated layout has no nested copies to race over, honours the workspace
  # filter (hoisted installed ~3GB, this ~1.5GB), and builds unchanged. The
  # store fetched above does not depend on the linker.
  pnpmInstallFlags = [ "--node-linker=isolated" ];

  nativeBuildInputs = [ nodejs_24 pnpm_10 pnpmConfigHook makeWrapper ];

  buildPhase = ''
    runHook preBuild
    # pnpmConfigHook patches the ROOT node_modules only, and each workspace
    # has a node_modules/.bin of its own (`tsc` in dynamic-workflow was the
    # one that failed on /usr/bin/env).
    while IFS= read -r -d "" d; do patchShebangs "$d"; done < <(
      find . -path ./node_modules -prune -o -type d -name node_modules -prune -print0)
    # Selects the production Built-in Provider file (config/provider/
    # zcode-builtin.json) rather than the test one.
    export ZCODE_ENV=production NODE_ENV=production
    # The same two steps as upstream's build:sea:prepare, minus the SEA
    # packaging: the CLI's workspace dependencies, then the CLI bundle.
    pnpm --filter="@zcode/cli^..." -r build
    pnpm --filter @zcode/cli build
    runHook postBuild
  '';

  # zcode.cjs inlines nearly everything, but leaves a few packages to be
  # loaded at run time, and one of them (@zcode/tui) is a bundle with
  # externals of its own. The list is read from upstream's build script
  # rather than written out here, so an update that adds one is copied
  # rather than discovered as a missing module on first launch.
  installPhase = ''
    runHook preInstall
    lib=$out/lib/zcode
    externals=$(node --input-type=module -e '
      const m = await import("./apps/zcode-cli/packages/cli/scripts/build.mjs");
      console.log(m.resolveBuildExternal().join(","));')
    echo "runtime externals: $externals"
    node ${./runtime-closure.mjs} . "$lib" "apps/zcode-cli/packages/cli:$externals"
    mkdir -p $lib/apps/zcode-cli/packages/cli
    cp -r apps/zcode-cli/packages/cli/dist $lib/apps/zcode-cli/packages/cli/
    # 57MB, and nothing reads it without --enable-source-maps.
    rm -f $lib/apps/zcode-cli/packages/cli/dist/zcode.cjs.map
    echo "$externals" > $lib/externals
    install -Dm644 -t $out/share/doc/zcode LICENSE NOTICE.md
    # rg on PATH, after the user's own: ZCode's shell tool expects one and
    # otherwise falls back to a slower WASM build inside the bundle.
    makeWrapper ${lib.getExe nodejs_24} $out/bin/zcode \
      --add-flags $lib/apps/zcode-cli/packages/cli/dist/zcode.cjs \
      --suffix PATH : ${lib.makeBinPath [ ripgrep ]}
    runHook postInstall
  '';

  # A missing external is a CLI that starts and then dies on the first
  # import that needs it, so load every one the way the bundle will: from
  # its own directory, by bare name.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$(mktemp -d)
    $out/bin/zcode --version
    ( cd $out/lib/zcode/apps/zcode-cli/packages/cli/dist
      for m in $(tr , ' ' < $out/lib/zcode/externals); do
        node --input-type=module -e "await import('$m')" \
          || { echo "runtime external $m does not load" >&2; exit 1; }
      done )
    runHook postInstallCheck
  '';

  meta = {
    description = "Z.ai's coding agent, terminal CLI";
    homepage = "https://github.com/zai-org/ZCode";
    license = lib.licenses.asl20;
    mainProgram = "zcode";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
})
