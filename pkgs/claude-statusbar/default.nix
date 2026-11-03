{ lib, python3Packages, src }:

python3Packages.buildPythonApplication {
  pname = "claude-statusbar";
  version = (lib.importTOML "${src}/pyproject.toml").project.version;
  pyproject = true;

  inherit src;

  build-system = [ python3Packages.setuptools ];

  # Upstream tests need pytest plus live Claude session data; skip.
  doCheck = false;

  # cs re-launches itself as `sys.executable -m claude_statusbar...` for the
  # background daemon, its render workers and the git/balance refreshers. The
  # Nix wrapper only puts site-packages on the path of the `cs` process
  # itself, so those children died with ModuleNotFoundError: no daemon ever
  # ran, every 1Hz tick rendered inline through 2 machine-wide slots, and the
  # losers printed "cs: warming up…". Export the path so children inherit it
  # (upstream has no runtime deps, so $out alone is enough).
  # Auto-upgrade shells out to pip, which can't touch the store; Nix owns
  # the version.
  makeWrapperArgs = [
    "--prefix" "PYTHONPATH" ":" "${placeholder "out"}/${python3Packages.python.sitePackages}"
    "--set" "CLAUDE_STATUSBAR_NO_UPDATE" "1"
  ];

  meta = with lib; {
    description = "Status bar monitor for Claude Code showing 5h/7d rate-limit usage, model, and context window";
    homepage = "https://github.com/leeguooooo/claude-code-usage-bar";
    license = licenses.mit;
    mainProgram = "cs";
  };
}
