{
  description = "A widget framework for building desktop shells, written and configurable in Python";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default-linux";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    gvc = {
      url = "github:ignis-sh/libgnome-volume-control-wheel";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      gvc,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = import ./nix/version.nix { inherit self; };
      in
      {
        packages = rec {
          ignis = pkgs.callPackage ./nix { inherit self gvc version; };
          default = ignis;
        };
        apps = rec {
          ignis = flake-utils.lib.mkApp { drv = self.packages.${system}.ignis; };
          default = ignis;
        };

        formatter = pkgs.nixfmt-rfc-style;

        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.ignis ];

            packages = with pkgs; [
              ruff
              mypy
            ];

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.gtk4-layer-shell ];
          };
        };
      }
    )
    // {
      overlays.default = final: prev: { inherit (self.packages.${prev.system}) ignis; };
    };
}
