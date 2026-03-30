{ lib, ... }:
let
  mkVmSecret = name: {
    file = ./. + "/${name}.age";
    owner = "root";
    group = "kvm";
    mode = "0440";
  };

  secretNames = builtins.map (name: lib.removeSuffix ".age" name) (
    builtins.attrNames (import ./secrets.nix)
  );
in
{
  config.age.secrets = lib.genAttrs secretNames mkVmSecret;
}
