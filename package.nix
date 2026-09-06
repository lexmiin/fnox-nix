{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}: let
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-m3M6K54+iT5zExzDx9ZMhZbeTHIQtH82le1AEdeYoeY=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-d+kgsh5Cr53w1r8bulitlcvyhVcAnxcsc9sv6mUcmWI=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-6ocZbEFp/fYXCnJGw+42Q89un9V9OMOaBibvBcJTHZE=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-SRqqtJhDXp7f3YVh3cVxpoTOxJzuZT8pRUS83wSFfMo=";
    };
  };
in
  stdenvNoCC.mkDerivation rec {
    pname = "fnox";
    version = "1.35.1";

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
