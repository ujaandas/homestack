{ config, lib, ... }:
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
  options.secrets = lib.genAttrs secretNames (name: {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the ${name} secret.";
    };
  });

  config.age.secrets = genAttrs secretNames (
    name: lib.optionalAttrs config.secrets.${name}.enable (mkVmSecret name)
  );
}
