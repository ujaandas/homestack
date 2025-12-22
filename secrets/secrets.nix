let
  homelab-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBil3FzXGvZkdYDp+aVkdR7c8Puld/EkumZmjp/4fdT ujaandas03@gmail.com";
  homelab-sys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGNZec+i+8JUzF6OIZkozl9FaN75bah8xX7TX4+TXER root@homelab";
  homelab-root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjAWoqQYGYE9OsJTTYesDt1xm89rVSMVZUiW07UWsvI root@nixos";
in
{
  "pocketid_enc_key.age".publicKeys = [
    homelab-user
    homelab-sys
    homelab-root
  ];
  "cloudflare_dns_key.age".publicKeys = [
    homelab-user
    homelab-sys
    homelab-root
  ];
  "netbird_pocketid_api_key.age".publicKeys = [
    homelab-user
    homelab-sys
    homelab-root
  ];
  "netbird_turn_key.age".publicKeys = [
    homelab-user
    homelab-sys
    homelab-root
  ];
  "netbird_relay_key.age".publicKeys = [
    homelab-user
    homelab-sys
    homelab-root
  ];
  "netbird_data_store_enc_key.age".publicKeys = [
    homelab-user
    homelab-sys
    homelab-root
  ];
}
