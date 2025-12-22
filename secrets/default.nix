{ config, lib, ... }:
let

  inherit (lib)
    mkOption
    genAttrs
    optionalAttrs
    removeSuffix
    map
    ;

  inherit (lib.types) bool;

  secretdir = "/home/homelab/homelab/secrets";

  # helper to generate vm-readable secret
  # TODO: how can i restrict this to readable by certain vms?
  mkVmSecret = name: {
    file = "${secretdir}/${name}.age";
    owner = "root";
    group = "kvm";
    mode = "0440";
  };

  secrets = map (name: removeSuffix ".age" name) (builtins.attrNames (import ./secrets.nix));
in
{
  options.secrets = genAttrs secrets (name: {
    enable = mkOption {
      type = bool;
      default = true;
      description = "Enable the ${name} secret.";
    };
  });

  config.age.secrets = genAttrs secrets (
    name: optionalAttrs config.secrets.${name}.enable (mkVmSecret name)
  );
}
