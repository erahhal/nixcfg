# AGENTS.md

## Builds

Never run `nix build`, `nixos-rebuild`, `home-manager switch`, or any other
build/realisation command without asking first. These commands can be slow,
pull large closures, and modify the running system. Always propose the
command and wait for explicit approval before executing.

When a build is approved, use `nix run .#switch` (the project's flake app)
unless you specifically need options that app doesn't expose. Propose any
deviation in the same approval request.

## Local-model guardrails (Qwen / GLM / gpt-oss served from logistikon)

Frontier models (Claude, GPT, Gemini): ignore this section — it exists to
keep the small local models inside their context and sampling limits and
does not apply to you.

Large, repetitive text in the conversation (build logs, lockfile diffs,
hexdumps) blows the context budget and can trigger degenerate repetition
loops — one unfiltered `nixos-rebuild` log has already poisoned a session
into an 11-minute stream of garbage. Therefore:

- Never put raw build or test output into the conversation. Run builds as
  `<cmd> 2>&1 | tail -n 100`; if that isn't enough, grep the log for
  `error:` and show only matching lines with a few lines of context.
- Judge success by exit code plus targeted grep, not by reading a whole
  log. The same applies to `nix log` output.
- Read big or generated files in slices (search first, then a line
  range) — never whole. This especially means `flake.lock` and anything
  over a few hundred lines.
- Never cat binary or generated artifacts (images, archives, store
  outputs).
- Don't echo large tool output back in your reply; summarize it in a
  sentence or two.
- Prefer several small, verified steps over one sweeping change; keep
  each response short.
