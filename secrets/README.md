# Secrets

This folder contains all encrypted secrets used by the homelab. 
Secrets are managed with `agenix`, and the Nix module here (`default.nix`) automatically discovers and exposes them as options.

## Adding a new secret

1. Open `secrets.nix`
2. Add a new entry following the existing pattern:
```nix
"netbird_pocketid_api_key.age".publicKeys = [
  homelab-user
  homelab-sys
  homelab-root
];
```
> The attribute name must end with .age

3. Encrypt the secret:
```bash
nix run github:ryantm/agenix -- -e netbird_pocketid_api_key.age
```

The module will read from `secrets.nix` and generate an option under `secrets.netbird_pocketid_api_key.enable`, as well
as expose the corresponding `agenix` option under `config.age.secrets`.

## Using a secret in a MicroVM

Currently, I think using secrets is kind of janky. As you can see in `default.nix`, I've given the `kvm` role permission to read the decrypted secret.
This is because we basically pass the decrypted secret in using `systemd.io.Credentials`. How you consume or actually read the secret inside the MicroVM
might be a bit janky. Worst case, you basically make it an environment variable. Best case, you can just set whatever secret option you want to `%d/SECRET`.
Check the docs for `systemd.io.Credentials` [here](https://systemd.io/CREDENTIALS/) for more details.