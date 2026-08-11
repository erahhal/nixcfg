{ lib
, stdenv
, bash
, python313
, fetchurl
, makeWrapper
}:

let
  hermesVersion = "0.19.0";

  # Python environment with all hermes dependencies
  # Hermes requires Python >=3.11,<3.14 so we use python313
  hermesPython = python313.withPackages (ps: with ps; [
    # Core dependencies
    openai
    certifi
    fire
    httpx
    rich
    tenacity
    pyyaml
    ruamel-yaml
    requests
    jinja2
    pydantic
    prompt-toolkit
    croniter
    packaging
    markdown
    pyjwt
    urllib3
    cryptography
    psutil
    websockets
    pathspec
    fastapi
    uvicorn
    python-multipart
    ptyprocess
    pillow
    python-dotenv
    # MCP client SDK. hermes calls this an OPTIONAL dependency and means it:
    # tools/mcp_tool.py wraps `from mcp import ClientSession` in a try/except
    # and, on ImportError, sets _MCP_AVAILABLE = False and becomes a no-op
    # that logs at DEBUG. So without this the `mcp_servers` block in
    # config.yaml is read, validated, and silently does nothing — hermes
    # starts clean and simply has no tools, which is the failure mode that
    # takes longest to notice. It also wants >= 1.24.0 for the
    # non-deprecated streamable_http_client (nixpkgs has 1.27.1).
    mcp
    # Build dependencies
    setuptools
    wheel
    build
    pip
  ]);
in

stdenv.mkDerivation (finalAttrs: {
  pname = "hermes";
  version = hermesVersion;

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/c1/2c/5eca471374c1b48555a8f0b988c06b19a93ae33a6c0e67845e47fc3a5628/hermes_agent-0.19.0.tar.gz";
    hash = "sha256-rJhr7eZKJ4VDZnbA6ghOxYZXT4ywCp0EfglbQ10+IcA=";
  };

  nativeBuildInputs = [
    hermesPython
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    # Install hermes into the output directory
    mkdir -p $out/lib/hermes
    ${hermesPython}/bin/python -m pip install \
      --target=$out/lib/hermes \
      --no-deps \
      --no-build-isolation \
      "$src"

    # Create wrapper that sets up Python path
    # Entry point is hermes_cli.main:main
    mkdir -p $out/bin
    makeWrapper ${hermesPython}/bin/python $out/bin/hermes \
      --add-flags "-m hermes_cli.main" \
      --set PYTHONPATH "$out/lib/hermes"

    # Create additional entry points
    makeWrapper ${hermesPython}/bin/python $out/bin/hermes-agent \
      --add-flags "-m run_agent" \
      --set PYTHONPATH "$out/lib/hermes"

    makeWrapper ${hermesPython}/bin/python $out/bin/hermes-acp \
      --add-flags "-m acp_adapter.entry" \
      --set PYTHONPATH "$out/lib/hermes"

    runHook postInstall
  '';

  doCheck = false;

  meta = with lib; {
    description = "Self-improving AI agent by Nous Research";
    homepage = "https://hermes-agent.nousresearch.com/";
    license = licenses.mit;
    mainProgram = "hermes";
    platforms = platforms.linux ++ platforms.darwin;
  };
})
