{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Final derivation including any overrides made to output package
        inherit (self.packages.${system}) py-start;

        devPkgs =
          with pkgs;
          [
            black
            isort
            python3.pkgs.pytest
            python3.pkgs.venvShellHook
            shfmt
          ]
          ++ py-start.buildInputs;

        mkApp = text: {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "app";
              runtimeInputs = devPkgs;
              inherit text;
            }
          );
        };
      in
      {
        packages = {
          default = py-start;

          py-start = pkgs.python3.pkgs.callPackage ./. { };

          py-start-test = py-start.override {
            doCheck = true;
          };
        };

        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [ py-start ];
            nativeBuildInputs = devPkgs;
            venvDir = ".venv";
            postVenvCreation = ''
              pip install -e '.[dev]'
            '';
          };
        };

        apps = {
          format = mkApp ''
            ./format.sh
          '';
        };

        formatter = pkgs.nixfmt;
      }
    );
}
