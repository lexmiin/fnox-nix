{
  description = "Nix flake for fnox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    overlay = final: _prev: {
      fnox = final.callPackage ./package.nix {};
    };

    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [overlay];
      };
  in {
    overlays.default = overlay;

    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.fnox;
      fnox = pkgs.fnox;
    });

    apps = forAllSystems (system: {
      default = self.apps.${system}.fnox;
      fnox = {
        type = "app";
        program = "${self.packages.${system}.fnox}/bin/fnox";
      };
    });

    checks = forAllSystems (system: {
      fnox = self.packages.${system}.fnox;
    });

    formatter = forAllSystems (system: let
      pkgs = pkgsFor system;
    in
      pkgs.writeShellApplication {
        name = "fnox-nix-fmt";
        runtimeInputs = [pkgs.alejandra];
        text = ''
          if [ "$#" -eq 0 ]; then
            alejandra .
          else
            alejandra "$@"
          fi
        '';
      });

    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          gh
          jq
          nix-prefetch-github
          python3
        ];
      };
    });
  };
}
