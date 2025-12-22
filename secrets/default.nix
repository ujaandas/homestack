{ config, lib, ... }:
let

  inherit (lib)
    mkIf
    genAttrs
    mkOption
    foldl'
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

  # helper for use in agenix secret enabling
  mkEnabledSecret =
    name:
    mkIf config.secrets.${name}.enable {
      ${name} = mkVmSecret name;
    };

  secrets = [
    "pocketid_enc_key"
    "cloudflare_dns_key"
    "netbird_pocketid_api_key"
    "netbird_turn_key"
    "netbird_relay_key"
    "netbird_data_store_enc_key"
  ];
in
{
  options.secrets = genAttrs secrets (name: {
    enable = mkOption {
      type = bool;
      default = true;
      description = "Enable the ${name} secret.";
    };
  });

  config.age.secrets = foldl' (acc: name: acc // mkEnabledSecret name) { } secrets;
}
