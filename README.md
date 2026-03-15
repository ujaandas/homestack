# 🏠 homestack
Welcome home! This is Homestack, a fully declarative, multi-layered private "cloud-at-home" architecture. Built on NixOS it treats infrastructure as code to create a reproducible, modular, and cryptographically secure service environment.

## Overview
Homestack decouples services from hardware. By leveraging MicroVM.nix, I run a fleet of specialized, single-purpose guests on top of a hardened NixOS host. This architecture ensures that even if one service is compromised, the rest of the stack remains isolated.

#### Hosts
The physical (or cloud) layer that orchestrates the guests:
- `homelab`: my primary local hypervisor. Manages the bridge networking, NAT routing, and hardware-specific secrets
- `cloud-relay`: a specialized cloud host (VPS) acting as a public anchor. It bypasses restrictive local NATs via reverse tunnels, providing a stable entry point for external users

#### Guests 
We adhere to the Single Responsibility Principle. Each guest is a specialized MicroVM:
- `auth` (PocketID): the Identity Provider (IdP). The source of truth for all users via OIDC
- `vpn` (NetBird): a mesh VPN that creates peer-to-peer encrypted tunnels between all my devices
- `proxy` (Caddy & Dnsmasq): the traffic controller. Handles SSL/TLS termination and internal service discovery
- `db` (Postgres): the persistent data layer for the stack, isolated from the public-facing proxy

> #### Why NixOS?
> - Atomic reproducibility: the entire environment—from OIDC scopes to firewall rules—can be recreated on a new machine in minutes with bitwise precision
> - DRY modules: Using a custom module system, I define service logic once (e.g., `modules/services/netbird.nix`) and "consume" it across any host I choose
> - Generational rollbacks: every change creates a new system generation. If a config is faulty, I simply reboot into the previous version

## How it Works

### Networking
Traffic is routed through a tiered virtual network:
1. Ingress: External traffic hits the Cloud VPS or the local Proxy VM
2. Resolution: Internal Dnsmasq intercepts \*.ujaan.me requests, resolving them to internal bridge IPs (192.168.100.x)
3. Encryption: Caddy manages wildcard certificates via Cloudflare DNS-01 challenges, allowing for valid HTTPS on internal-only IPs

