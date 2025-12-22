{ config, ... }:
{
  imports = [
    ../../secrets
  ];

  secrets = {
    pocketid_enc_key.enable = true;
    cloudflare_dns_key.enable = true;
    netbird_pocketid_api_key.enable = true;
    netbird_turn_key.enable = true;
    netbird_relay_key.enable = true;
    netbird_data_store_enc_key.enable = true;
  };

  microvm = {
    autostart = [
      "db"
      "auth"
      "proxy"
      "vpn"
    ];
    vms = {
      db.config = import ../../vms/db;
      auth.config = import ../../vms/auth;
      proxy.config = import ../../vms/proxy;
      vpn.config = import ../../vms/vpn;
    };
  };
}
