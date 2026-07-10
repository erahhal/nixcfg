{ lib, python3Packages, src }:

python3Packages.buildPythonApplication {
  pname = "claude-statusbar";
  version = (lib.importTOML "${src}/pyproject.toml").project.version;
  pyproject = true;

  inherit src;

  build-system = [ python3Packages.setuptools ];

  # Upstream tests need pytest plus live Claude session data; skip.
  doCheck = false;

  meta = with lib; {
    description = "Status bar monitor for Claude Code showing 5h/7d rate-limit usage, model, and context window";
    homepage = "https://github.com/leeguooooo/claude-code-usage-bar";
    license = licenses.mit;
    mainProgram = "cs";
  };
}
