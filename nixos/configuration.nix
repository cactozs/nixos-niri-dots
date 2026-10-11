# Thin entry point. Real config lives in ./modules/*.nix,
# user packages live in ./home/cactoz.nix (home-manager).
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/nix.nix
    ./modules/boot.nix
    ./modules/network.nix
    ./modules/nvidia.nix
    ./modules/desktop.nix
    ./modules/system.nix
    ./modules/users.nix
  ];

  networking.hostName = "nixos";

  # First install release. Do not change.
  # https://nixos.org/nixos/options.html#opt-system.stateVersion
  system.stateVersion = "26.05";
}
