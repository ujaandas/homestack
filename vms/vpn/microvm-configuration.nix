{
  microvm = {
    mem = 1024;
    vcpu = 1;

    volumes = [
      {
        mountPoint = "/";
        image = "root.img";
        size = 512;
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
    ];

    interfaces = [
      {
        type = "tap";
        id = "vpn";
        mac = "02:00:00:00:00:04";
      }
    ];

    credentialFiles = {
      COTURN = "/run/agenix/coturn";
      NETBIRD = "/run/agenix/netbird";
    };
  };
}
