{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  runCommand,
  jq,
}:
let
  version = "1.52.2";
  # npm dependency install fails with nodejs_24: https://github.com/NixOS/nixpkgs/issues/474535
  nodejs = nodejs_22;
  src = fetchFromGitHub {
    owner = "ory";
    repo = "polis";
    tag = "v${version}";
    hash = "sha256-2TbfrFZtAbLQYI4l49UMjIe11+VuJCbaHfsgGIf+It8=";
  };
  npmDepsFetcherVersion = 2;
  internal-ui = buildNpmPackage {
    inherit src version nodejs npmDepsFetcherVersion;
    pname = "internal-ui";
    sourceRoot = "${src.name}/internal-ui";
    npmFlags = [ "--legacy-peer-deps" ];
    npmDepsHash = "sha256-Hbpv4AReyPSTzpSgZXiDJ2+QMokfzP+izr8obUfI0H0=";
    #makeCacheWritable = true;
    dontNpmBuild = true;
    buildPhase = ''
      runHook preBuild
      npm install --legacy-peer-deps
      # npm run build
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      cp -r . "$out"
      runHook postInstall
    '';
  };
  npm = buildNpmPackage {
    inherit src version nodejs npmDepsFetcherVersion;
    pname = "npm";
    sourceRoot = "${src.name}/npm";
    npmFlags = [ "--legacy-peer-deps" ];
    npmDepsHash = "sha256-xUFPrzdnpzlky3bOeHdi5+pNZfhQ7nZ1mr9IPE7RIhA=";
    installPhase = ''
      runHook preInstall
      cp -r . "$out"
      runHook postInstall
    '';
  };
in
buildNpmPackage rec {
  inherit src version nodejs npmDepsFetcherVersion;
  pname = "polis";
  sourceRoot = "${src.name}";
  postPatch = ''
    mkdir -p npm/node_modules
    ln -s ${npm}/node_modules npm/node_modules
  '';
    # mkdir -p internal-ui/node_modules
    # ln -s ${internal-ui}/node_modules internal-ui/node_modules

    # chmod +w internal-ui
    # ln -s ${internal-ui}/node_modules internal-ui/node_modules

  env = {
    NEXT_TELEMETRY_DISABLED = 1;
  };
  # NODE_OPTIONS = "--openssl-legacy-provider";
  npmDepsHash = "sha256-WhsY+cBtRlXnMhrG4wCauje8OScbrbv8dmhFWFVfSi0=";
  npmFlags = [
    # upstream `package.json` [1] has a `prepare` script defined which is root
    # cause of issues when packaging this project with `buildNpmPackage`. This
    # script is invoked automatically as part of `npm install` since npm@v4 [2].
    #"--ignore-scripts"
    "--no-fund"
    "--legacy-peer-deps"
    "--loglevel=silly"
  ];
  makeCacheWritable = true; # for sharp
  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall

    mv .next/standalone $out
    mv .next/static $out/.next/static
    cp -R public $out/public

    runHook postInstall
  '';

  meta = {
    description = "wip";
    homepage = "https://ory.com/polis";
    license = lib.licenses.apsl20;
    maintainers = with lib.maintainers; [
      debtquity
    ];
  };
}
