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
        id = "auth";
        mac = "02:00:00:00:00:02";
      }
    ];

    credentialFiles = {
      POCKETID_ENC_KEY = "/run/agenix/pocketid_enc_key";
    };
  };
}
