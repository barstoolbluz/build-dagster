{
  description = "Dagster orchestration platform - all packages in a single closure (unofficial Nix package)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Import our Nix expression from .flox/pkgs/
        dagster = pkgs.callPackage ./.flox/pkgs/dagster.nix { };
      in
      {
        packages = {
          default = dagster;
          dagster = dagster;
        };

        apps = {
          default = {
            type = "app";
            program = "${dagster}/bin/dagster";
          };
          dagster-webserver = {
            type = "app";
            program = "${dagster}/bin/dagster-webserver";
          };
          dagster-daemon = {
            type = "app";
            program = "${dagster}/bin/dagster-daemon";
          };
          dagster-graphql = {
            type = "app";
            program = "${dagster}/bin/dagster-graphql";
          };
          dagster-webserver-debug = {
            type = "app";
            program = "${dagster}/bin/dagster-webserver-debug";
          };
          dagster-init-config = {
            type = "app";
            program = "${dagster}/bin/dagster-init-config";
          };
          dagster-info = {
            type = "app";
            program = "${dagster}/bin/dagster-info";
          };
          dagster-welcome = {
            type = "app";
            program = "${dagster}/bin/dagster-welcome";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ dagster ];
          inputsFrom = [ dagster ];
        };
      });
}
