{ ... }:

{
  networking.networkmanager.enable = true;

  services.tailscale.enable = true;

  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
