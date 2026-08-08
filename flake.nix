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
            just
          ];
        };

        checks = deploy-rs.lib.${system}.deployChecks self.deploy;

        formatter = pkgs.writeShellApplication {
          name = "format";
          runtimeInputs = [ pkgs.nixfmt-tree ];
          text = "treefmt --walk git";
        };
      }
    )
    // {
      # nixosConfigurations = {};
      # deploy = { };
    };
}
