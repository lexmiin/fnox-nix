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
      hash = "sha256-KCBGo7dgtiPNQe5NzZq6c6a1RHSy1OoDOyWjn3x7X6c=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-Sxrx06lg3joUqM9r+fZmcM/q3Wq0HBj5bi/8EkDEVpE=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-7M7LSsbvZsoAO8tDQxUYz9vDV6u887W28y+Wv0cYeWk=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-cw+k55wicPhz+4gwGJCfaUXN3YbPdFqbj+7Tn6dVOhA=";
    };
  };
in
  stdenvNoCC.mkDerivation rec {
    pname = "fnox";
    version = "1.33.0";

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
