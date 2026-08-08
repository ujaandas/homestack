{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      deploy-rs,
      openwrt-imagebuilder,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Build packages or images
        packages = {
          linksys-mx2000 = pkgs.callPackage ./img/linksys-mx2000 {
            inherit openwrt-imagebuilder;
          };
        };

        # Devshell for dev machines (e.g., macbook) AND actual homelab nodes
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkgs.deploy-rs
            just
            just-lsp
            just-formatter
            statix
            nixfmt-tree
          ];
        };

        # Checks to run during deployment
        checks = {
          statix-lint = pkgs.runCommand "statix-lint" { buildInputs = [ pkgs.statix ]; } ''
            statix check ${self}
            touch $out
          '';
        }
        // deploy-rs.lib.${system}.deployChecks self.deploy;

        # Formatting
        formatter = pkgs.writeShellApplication {
          name = "format";
          runtimeInputs = [ pkgs.nixfmt-tree ];
          text = "treefmt --walk git";
        };
      }
    )
    // {
      # Define homelab host "configs" here
      # nixosConfigurations = {};

      # Define homelab host "deployments" here
      deploy = {
        nodes = { };
      };
    };
}
