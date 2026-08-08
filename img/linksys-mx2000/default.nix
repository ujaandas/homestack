{
  pkgs,
  openwrt-imagebuilder,
}:

let
  # Consider using this later for custom configs
  # customFiles = ./files;
in
openwrt-imagebuilder.lib.build {
  inherit pkgs;

  release = "25.12.5";
  target = "qualcommax";
  variant = "ipq50xx";
  profile = "linksys_mx2000";

  # Packages baked into ROM
  packages = [
    "luci"
    "luci-ssl"
    "-dnsmasq" # Remove standard dnsmasq...
    "dnsmasq-full" # ...and replace with full version
    "htop"
    "tcpdump"
  ];

  # Uncomment for custom configs
  # files = customFiles;
}
