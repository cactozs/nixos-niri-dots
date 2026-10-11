# User + privilege escalation.
# sudo kept ENABLED: nixos-rebuild/nh expect sudo. doas stays for interactive use.
{ pkgs, ... }:

{
  users.users."cactoz" = {
    isNormalUser = true;
    description = "cactoz";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [ ];
    shell = pkgs.bash;
  };

  security.sudo.enable = true;
  security.doas = {
    enable = true;
    extraRules = [
      {
        groups = [ "wheel" ];
        keepEnv = true;
        persist = true;
      }
    ];
  };
}
