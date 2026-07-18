{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  makeWrapper,
  usage,
}: let
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-pPe1ds4KS6XTB121ncDC8HSfb6bYoI8rVGWI07+WtEw=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-Q1GkC28GSatLal0bhw1g0rLWhLZrkbt47KwPSyeNbL4=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-d50st7zvqB1X4mm/1f/fOcqWHVJrBs+zW3qmcLNcHGo=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-0ibhDLFpjCrQWiDuliaUYNmxuntMwp8Gkem1oKeNeu4=";
    };
  };
in
  stdenvNoCC.mkDerivation rec {
    pname = "fnox";
    version = "1.31.0";

    src = let
      system = stdenvNoCC.hostPlatform.system;
      release =
        releases.${system}
        or (throw "fnox-nix: unsupported system ${system}");
    in
      fetchurl {
        url = "https://github.com/jdx/fnox/releases/download/v${version}/fnox-${release.target}.tar.gz";
        inherit (release) hash;
      };

    nativeBuildInputs = [
      installShellFiles
      makeWrapper
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -Dm755 fnox $out/bin/fnox
      wrapProgram $out/bin/fnox \
        --prefix PATH : "${lib.makeBinPath [usage]}"

      $out/bin/fnox completion bash > fnox.bash
      $out/bin/fnox completion fish > fnox.fish
      $out/bin/fnox completion zsh > _fnox

      substituteInPlace fnox.bash fnox.fish _fnox \
        --replace-fail '-p usage' '-p ${lib.getExe usage}' \
        --replace-fail 'usage complete-word' '${lib.getExe usage} complete-word'

      installShellCompletion --cmd fnox \
        --bash fnox.bash \
        --fish fnox.fish \
        --zsh _fnox

      runHook postInstall
    '';

    meta = {
      description = "Encrypted and remote secret manager";
      homepage = "https://github.com/jdx/fnox";
      license = lib.licenses.mit;
      mainProgram = "fnox";
      platforms = builtins.attrNames releases;
    };
  }
