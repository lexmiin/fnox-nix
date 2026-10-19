{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}: let
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-+2R71COFh1CuSdk6WltP55fz6HAJHJYyco1G7Dg1CCo=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-Gjg/IE/2SsjtFkjroywlqrFnSqyLQmql/cljpEGidjA=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-xjy2rC6i1KD5lIrVev9O8i1N782xHVVFFlW9D2WjY+Q=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-Mm13u5V4LqP2zNXMe2e5QCluoye4ujlQyXW/nTu1SMs=";
    };
  };
in
  stdenvNoCC.mkDerivation rec {
    pname = "fnox";
    version = "1.41.0";

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
