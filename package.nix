{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}: let
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-P26bT3pZpXEqvkjPbJeyoGADkrXLVAWagLU0l63qs1Q=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-77GoMLC0RwS5PRZHyrm5BG2nUZqGnMbeNDegKMfbdBc=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-4B2WH9Zou2eKD94QgFdlHEBJfWoIb5sy+ky7iv4hWx8=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-ndvT6DBPS9Gq5Z8BUu/Y7IEK2pZW5kznUz1MRviq6YU=";
    };
  };
in
  stdenvNoCC.mkDerivation rec {
    pname = "fnox";
    version = "1.35.2";

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

    nativeBuildInputs = [installShellFiles];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -Dm755 fnox $out/bin/fnox

      $out/bin/fnox completion bash > fnox.bash
      $out/bin/fnox completion fish > fnox.fish
      $out/bin/fnox completion zsh > _fnox

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
