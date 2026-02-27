{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_22
, pkg-config
, python3
, makeWrapper
, cairo
, pango
, libjpeg
, giflib
, librsvg
, pixman
, ripgrep
, fd
, git
}:

buildNpmPackage rec {
  pname = "pi";
  version = "0.55.0";

  src = fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    rev = "v${version}";
    hash = "sha256-+T10MIxdRPHWAeXWur2JkonBgLZtBgCUM931QRWhBM4=";
  };

  npmDepsHash = "sha256-XbWzA84uAmANa2gNUa5FqSykS+94KF50h3uJ2LFSmGU=";

  nodejs = nodejs_22;

  nativeBuildInputs = [ pkg-config python3 makeWrapper ];
  buildInputs = [ cairo pango libjpeg giflib librsvg pixman ];

  npmBuildScript = "build";

  # Skip model generation step which requires network access
  preBuild = ''
    substituteInPlace packages/ai/package.json \
      --replace-fail '"build": "npm run generate-models && tsgo -p tsconfig.build.json"' \
      '"build": "tsgo -p tsconfig.build.json"'
  '';

  dontNpmInstall = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/pi-monorepo
    cp -r . $out/lib/node_modules/pi-monorepo/
    rm -rf $out/lib/node_modules/pi-monorepo/node_modules/.bin

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/pi \
      --add-flags "$out/lib/node_modules/pi-monorepo/packages/coding-agent/dist/cli.js" \
      --set PI_PACKAGE_DIR "$out/lib/node_modules/pi-monorepo/packages/coding-agent" \
      --prefix PATH : ${lib.makeBinPath [ ripgrep fd git ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "A minimal terminal AI coding agent";
    homepage = "https://pi.dev/";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "pi";
  };
}
