# 🏡 homestack

A reproducible NixOS‑based homelab stack.  

## 🗂️ Project Structure

- `flake.nix` - Entry point, defines toggles and shared module logic
- `hosts/` - All hardware and machine configurations
- `vms/` - All MicroVM configurations
- `secrets/` - Age‑encrypted secrets for each service

## 📦 How it Works

- Ideally, each host acts like a hypervisor, and manages VMs which contain the relevant NixOS service or relevant NixOS Containers.
- Each MicroVM should only handle 1 given service - keep them as separated as possible.
- Secrets are stored in `secrets/`, decrypted at runtime with `agenix`, then shared with KVM.
- The shared module defines toggles (`enableDb`, `enableAuth`, etc...) so you can split workloads across machines.

## 📋 TODO

- Harden secrets management (I don't like passing decrypted secrets)
- Fix and clean up SSH (use declarative SSH config aliases instead of `ssh default@192.168.100.4` each time)
- Improve support for multi-host systems (more `lib.options`)
- Beg NetBird to approve my PR so I can remove my overlay

## 🐛 Known Bugs

- Many
