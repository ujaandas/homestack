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

  release = "23.05.3";
  target = "x86/64";
  profile = "generic";

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
