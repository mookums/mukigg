{
  description = "The muki.gg website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
    iguana.url = "github:mookums/iguana";
  };

  outputs = {
    self,
    nixpkgs,
    iguana,
    ...
  }: let
    iguanaLib = iguana.lib.${system};

    mukiggPackage = iguanaLib.mkPackage {
      pname = "mukigg";
      version = "0.1.0";
      src = ./.;
    };

    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages.default = mukiggPackage;
    packages.mukigg = mukiggPackage;

    nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [./nix/service.nix];
      nixpkgs.overlays = final: prev: {mukigg = mukiggPackage;};
    };

    nixosModules.mukigg = self.nixosModules.default;

    devShells.${system}.default = iguanaLib.mkShell {
      withZls = true;

      extraPackages = with pkgs; [
        # Watch
        entr
        # Benchmarking
        wrk
      ];
    };
  };
}
