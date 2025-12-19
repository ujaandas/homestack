let
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
      db.config = import ../../vms/db;
      auth.config = import ../../vms/auth;
      proxy.config = import ../../vms/proxy;
      vpn.config = import ../../vms/vpn;
    };
  };
}
