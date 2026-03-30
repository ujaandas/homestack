{
  description = "a basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    hardware.url = "github:nixos/nixos-hardware/master";
    microvm.url = "github:astro/microvm.nix";
    agenix.url = "github:ryantm/agenix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      hardware,
      microvm,
      agenix,
    }:
    let
      username = "homelab";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkScript =
        name: text:
        pkgs.writeShellApplication {
          inherit name text;
          runtimeInputs = with pkgs; [
            nixfmt-tree
            statix
          ];
        };
    in
    {
      nixosConfigurations.sachiel = nixpkgs.lib.nixosSystem {
        specialArgs = inputs // {
          inherit username;
          inherit system;
        };
        inherit system;
        modules = [
          agenix.nixosModules.default
          microvm.nixosModules.host
          ./hosts/sachiel
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          self.packages.${system}.format
          self.packages.${system}.lint
          self.packages.${system}.check
          self.packages.${system}.test-all
          self.packages.${system}.rebuild
        ];
      };

      packages.${system} = {
        format = mkScript "format" ''treefmt --walk git'';
        lint = mkScript "lint" ''statix check --ignore result .direnv'';
        check = mkScript "check" ''nix flake check'';
        test-all = mkScript "test-all" ''check && format && lint'';
        rebuild = mkScript "rebuild" ''test-all && sudo nixos-rebuild switch --flake .\#sachiel'';
      };
    };
}
