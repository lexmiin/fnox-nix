# fnox-nix

Nix flake for [fnox](https://github.com/jdx/fnox), packaged from upstream release binaries.

## Usage

Add the flake input:

```nix
inputs.fnox-nix.url = "github:lexmiin/fnox-nix";
inputs.fnox-nix.inputs.nixpkgs.follows = "nixpkgs";
```

Then add the overlay:

```nix
inputs.fnox-nix.overlays.default
```

Install `pkgs.fnox` as usual.

You can also run it directly:

```sh
nix run github:lexmiin/fnox-nix -- --version
```

## Updating

The package is updated by `scripts/update.sh`:

```sh
scripts/update.sh
scripts/update.sh --version 1.28.0
```

The scheduled GitHub workflow checks the latest upstream release and opens a pull request when the package changes.
