{
  description = "The muki.gg website";

  nixConfig = {
    # Needed as zig fetch requires internet access.
    # What we could do is pull the underlying dependency and put
    # it in the global cache under .cache/zig/p/${hash}
    sandbox = false;
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
    zig.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls/0.13.0";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      overlays = [
        (final: prev: rec {
          zigpkgs = inputs.zig.packages.${prev.system};
          zig = zigpkgs."0.13.0";
          zls = inputs.zls.packages.${prev.system}.zls.overrideAttrs
            (old: { nativeBuildInputs = [ zig ]; });

          mukigg = prev.callPackage ./nix/package.nix { };
        })
      ];

      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit overlays system; };
    in {
      packages.default = pkgs.mukigg;
      packages.mukigg = pkgs.mukigg;

      nixosModules.default = { config, lib, pkgs, ... }: {
        imports = [ ./nix/service.nix ];
        nixpkgs.overlays = overlays;
      };

      nixosModules.mukigg = self.nixosModules.default;

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          zig
          zls
          # Watch
          entr
          # Debugging
          gdb
          valgrind
          # Benchmarking
          linuxPackages.perf
          wrk
        ];
      };

    };
}
