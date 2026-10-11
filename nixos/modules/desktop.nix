# Display stack. Only system-wide Wayland/Niri plumbing stays here,
# apps moved to home-manager (./home/cactoz.nix) for fast rebuilds.
{ pkgs, ... }:

{
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.niri.enable = true;
  services.displayManager.ly.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland
    xwayland-satellite
    kdePackages.breeze # Qt theme, referenced by Qt apps anywhere
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
