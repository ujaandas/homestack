{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      deploy-rs,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkgs.deploy-rs
            just
            statix
            nixfmt-tree
          ];
        };

        checks = {
          statix-lint = pkgs.runCommand "statix-lint" { buildInputs = [ pkgs.statix ]; } ''
            statix check ${self}
            touch $out
          '';
        }
        // deploy-rs.lib.${system}.deployChecks self.deploy;

        formatter = pkgs.writeShellApplication {
          name = "format";
          runtimeInputs = [ pkgs.nixfmt-tree ];
          text = "treefmt --walk git";
        };
      }
    )
    // {
      # nixosConfigurations = {};
      deploy = {
        nodes = { };
      };
    };
}
