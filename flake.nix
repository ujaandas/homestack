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
        checks = deploy-rs.lib.${system}.deployChecks self.deploy;
        devShells.default = pkgs.mkShell { };
      }
    )
    // {
      # nixosConfigurations = {};
      # deploy = { };
    };
}
