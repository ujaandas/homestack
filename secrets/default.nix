{ config, lib, ... }:
let
  cfg = config.homestack.host.secrets;

  mkVmSecret = name: {
    file = ./. + "/${name}.age";
    owner = "root";
    group = "kvm";
    mode = "0440";
  };

  availableSecretNames = builtins.map (name: lib.removeSuffix ".age" name) (
    builtins.attrNames (import ./secrets.nix)
  );
in
{
  options.homestack.host.secrets = {
    enabledNames = lib.mkOption {
      type = lib.types.listOf (lib.types.enum availableSecretNames);
      default = availableSecretNames;
      description = "Secret names to enable for this host.";
      example = [
        "cloudflare_dns_key"
        "wireguard_ingress_key"
      ];
    };
  };

  config.age.secrets = lib.genAttrs cfg.enabledNames mkVmSecret;
}
