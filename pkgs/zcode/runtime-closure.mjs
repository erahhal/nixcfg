// Copy what zcode.cjs still loads at run time out of the build tree.
//
// The CLI is one esbuild bundle that leaves four packages external
// (`resolveBuildExternal` in apps/zcode-cli/packages/cli/scripts/build.mjs),
// and one of those, @zcode/tui, is itself a bundle with externals of its own.
// The build tree's node_modules holds ~3GB of everything the workspace
// filter pulled in; this walks the dependency graph from those roots the way
// Node will resolve it and copies only what is reachable, at the SAME paths
// relative to the source root, so resolution in the output is resolution in
// the build tree.
//
//   node runtime-closure.mjs <sourceRoot> <outRoot> <fromDir>:<pkg>[,<pkg>...] ...
//
// Written against pnpm's ISOLATED layout (node_modules/.pnpm + symlinks),
// which is what the package installs with; see default.nix for why.
import {
  cpSync, existsSync, lstatSync, mkdirSync, readFileSync, readlinkSync,
  realpathSync, symlinkSync,
} from "node:fs";
import { dirname, join, relative, sep } from "node:path";

const [srcRoot, outRoot, ...rootSpecs] = process.argv.slice(2);
const root = realpathSync(srcRoot);
const copied = new Set();
const missing = [];

const platformOk = (pj) => {
  const match = (list, value) =>
    !Array.isArray(list) || list.length === 0
      ? true
      : list.some((v) => v === value) || (list.every((v) => v.startsWith("!")) && !list.includes(`!${value}`));
  const libc = (pj.libc ?? []).length ? pj.libc.includes("glibc") : true;
  return match(pj.os, process.platform) && match(pj.cpu, process.arch) && libc;
};

// Node's lookup: <dir>/node_modules/<name>, then each parent, never above root.
function lookup(name, fromDir) {
  for (let d = fromDir; ; d = dirname(d)) {
    const candidate = join(d, "node_modules", name);
    if (existsSync(join(candidate, "package.json"))) return candidate;
    if (d === root || !d.startsWith(root)) return null;
  }
}

function isWorkspace(realDir) {
  return !relative(root, realDir).split(sep).includes("node_modules");
}

function place(candidate) {
  // Recreate a workspace symlink where Node will look for it.
  const st = lstatSync(candidate);
  if (st.isSymbolicLink()) {
    const dest = join(outRoot, relative(root, candidate));
    if (!existsSync(dest)) {
      mkdirSync(dirname(dest), { recursive: true });
      symlinkSync(readlinkSync(candidate), dest);
    }
  }
}

function visit(candidate) {
  place(candidate);
  const real = realpathSync(candidate);
  if (copied.has(real)) return;
  copied.add(real);
  const pj = JSON.parse(readFileSync(join(real, "package.json"), "utf8"));
  const dest = join(outRoot, relative(root, real));
  mkdirSync(dest, { recursive: true });
  if (isWorkspace(real)) {
    // A workspace package ships its manifest and its build, never src.
    cpSync(join(real, "package.json"), join(dest, "package.json"));
    cpSync(join(real, "dist"), join(dest, "dist"), { recursive: true });
  } else {
    // Its own node_modules is copied package by package, as reached.
    const ownModules = join(real, "node_modules");
    cpSync(real, dest, {
      recursive: true,
      filter: (p) => p !== ownModules && !p.startsWith(ownModules + sep),
    });
  }
  const optional = new Set(Object.keys(pj.optionalDependencies ?? {}));
  const peersOptional = new Set(
    Object.entries(pj.peerDependenciesMeta ?? {}).filter(([, m]) => m?.optional).map(([n]) => n),
  );
  const deps = new Set([
    ...Object.keys(pj.dependencies ?? {}),
    ...optional,
    ...Object.keys(pj.peerDependencies ?? {}),
  ]);
  for (const dep of deps) {
    const found = lookup(dep, real);
    if (!found) {
      if (!optional.has(dep) && !peersOptional.has(dep)) missing.push(`${pj.name} -> ${dep}`);
      continue;
    }
    // A workspace package's build bundles its sibling workspaces (the TUI's
    // externals are exactly its non-@zcode dependencies), so those edges are
    // already inside its dist and are not followed.
    if (isWorkspace(real) && isWorkspace(realpathSync(found))) continue;
    const depPj = JSON.parse(readFileSync(join(found, "package.json"), "utf8"));
    if (optional.has(dep) && !platformOk(depPj)) continue;
    visit(found);
  }
}

// Each root is looked up from the workspace that declares it and then
// EXPOSED at <outRoot>/node_modules/<name>. The bundle inlines that
// workspace, so at run time the require comes from the CLI's dist instead,
// and under pnpm's isolated linker only the declaring package can see it.
for (const spec of rootSpecs) {
  const [from, names] = spec.split(":");
  for (const name of names.split(",")) {
    // Not every external is the CLI's own dependency (koffi is the
    // adapters'), so fall back to pnpm's hidden hoist of the whole store.
    const hidden = join(root, "node_modules", ".pnpm", "node_modules", name);
    const found = lookup(name, join(root, from))
      ?? (existsSync(join(hidden, "package.json")) ? hidden : null);
    if (!found) throw new Error(`runtime root ${name} not found from ${from}`);
    visit(found);
    const exposed = join(outRoot, "node_modules", name);
    if (!existsSync(exposed)) {
      mkdirSync(dirname(exposed), { recursive: true });
      symlinkSync(relative(dirname(exposed), join(outRoot, relative(root, realpathSync(found)))), exposed);
    }
  }
}

if (missing.length) {
  console.error("unresolved required dependencies:\n  " + missing.join("\n  "));
  process.exit(1);
}
console.log(`copied ${copied.size} packages`);
