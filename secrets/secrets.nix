let
  homelab-sachiel = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0qzwBbh1pvVIbliC0PnBVJkcdLYJhFEljw95Zre1i0 default@sachiel";
  homelab-root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjAWoqQYGYE9OsJTTYesDt1xm89rVSMVZUiW07UWsvI root@nixos";
in
{
  "pocketid_enc_key.age".publicKeys = [
    homelab-sachiel
    homelab-root
  ];
  "cloudflare_dns_key.age".publicKeys = [
    homelab-sachiel
    homelab-root
  ];
  "netbird_pocketid_api_key.age".publicKeys = [
    homelab-sachiel
    homelab-root
  ];
  "netbird_turn_key.age".publicKeys = [
    homelab-sachiel
    homelab-root
  ];
  "netbird_relay_key.age".publicKeys = [
    homelab-sachiel
    homelab-root
  ];
  "netbird_data_store_enc_key.age".publicKeys = [
    homelab-sachiel
    homelab-root
  ];
}
