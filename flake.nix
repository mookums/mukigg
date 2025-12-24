{
  description = "the muki.gg website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      fenix,
      crane,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        rustToolchain =
          with fenix.packages.${system};
          combine [
            stable.toolchain
            targets.wasm32-unknown-unknown.stable.rust-std
          ];
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
      in
      {
        devShells.default = craneLib.devShell {
          packages = with pkgs; [
            # rust
            rustToolchain
            wasm-pack

            # Javascript
            nodejs_24
            pnpm
            typescript
            typescript-language-server
            turbo
          ];
        };
      }
    );
}
