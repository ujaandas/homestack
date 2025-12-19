{
  description = "VPN VM configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    microvm.url = "github:astro/microvm.nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      microvm,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.vpn = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs // {
          inherit system;
        };
        modules = [
          microvm.nixosModules.microvm
          ./default.nix
        ];
      };
    };
}
