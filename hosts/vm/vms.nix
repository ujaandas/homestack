{
  db,
  auth,
  proxy,
  vpn,
  ...
}:
let
  vmdir = "/home/homelab/homelab/vms";
  secretdir = "/home/homelab/homelab/secrets";
in
{
  age.secrets = {
    pocketid = {
      file = "${secretdir}/pocketid.age";
      owner = "root";
      group = "kvm";
      mode = "0440";
    };

    cloudflare = {
      file = "${secretdir}/cloudflare.age";
      owner = "root";
      group = "kvm";
      mode = "0440";
    };

    coturn = {
      file = "${secretdir}/coturn.age";
      owner = "root";
      group = "kvm";
      mode = "0440";
    };

    netbird = {
      file = "${secretdir}/netbird.age";
      owner = "root";
      group = "kvm";
      mode = "0440";
    };
  };

  microvm = {
    autostart = [
      "db"
      "auth"
      "proxy"
      "vpn"
    ];
    vms = {
      db = {
        flake = db;
        updateFlake = "path:${vmdir}/db";
        restartIfChanged = true;
      };
      auth = {
        flake = auth;
        updateFlake = "path:${vmdir}/auth";
        restartIfChanged = true;
      };
      proxy = {
        flake = proxy;
        updateFlake = "path:${vmdir}/proxy";
        restartIfChanged = true;
      };
      vpn = {
        flake = vpn;
        updateFlake = "path:${vmdir}/vpn";
        restartIfChanged = true;
      };
    };
  };
}
