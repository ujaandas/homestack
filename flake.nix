{
  description = "a basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    hardware.url = "github:nixos/nixos-hardware/master";
    microvm.url = "github:astro/microvm.nix";
    agenix.url = "github:ryantm/agenix";

    # microvms
    db.url = "path:./vms/db";
    auth.url = "path:./vms/auth";
    proxy.url = "path:./vms/proxy";
    vpn.url = "path:./vms/vpn";

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      hardware,
      microvm,
      agenix,
      db,
      auth,
      proxy,
      vpn,
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
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        specialArgs = inputs // {
          inherit username;
          inherit system;
        };
        inherit system;
        modules = [
          agenix.nixosModules.default
          microvm.nixosModules.host
          ./hosts/vm
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          self.packages.${system}.build
          self.packages.${system}.activate
          self.packages.${system}.format
          self.packages.${system}.lint
          self.packages.${system}.check
          self.packages.${system}.test-all
          self.packages.${system}.rebuild
        ];
      };

      packages.${system} = {
        build = mkScript "build" ''sudo nixos-rebuild build --flake .\#vm'';
        activate = mkScript "activate" ''
          if [[ -e result/bin/switch-to-configuration ]]; then
            sudo result/bin/switch-to-configuration switch
          fi
        '';
        format = mkScript "format" ''treefmt --walk git'';
        lint = mkScript "lint" ''statix check --ignore result .direnv'';
        check = mkScript "check" ''nix flake check'';
        test-all = mkScript "test-all" ''check && format && lint && build'';
        rebuild = mkScript "rebuild" ''test-all && activate'';
      };
    };
}
