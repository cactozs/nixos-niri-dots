# home-manager for cactoz. This is your "imperative-like" layer:
# `nh home switch` here takes seconds, while `nh os switch` rebuilds the OS.
# System tools (drivers, docker, boot) stay in ../modules/*.nix.
{ pkgs, inputs, ... }:

{
  home.username = "cactoz";
  home.homeDirectory = "/home/cactoz";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Wayland / Niri desktop
    waybar
    alacritty
    wofi
    swaynotificationcenter
    awww
    cliphist
    wtype
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    adwaita-icon-theme
    wlogout
    hyprlock
    swayidle
    nautilus
    imv

    # Dev
    helix
    zed-editor
    yazi
    bat
    jq
    nodejs
    python3
    uv
    python3Packages.pip
    zellij

    # Apps / media
    firefox
    signal-desktop
    simplex-chat-desktop
    obsidian
    prismlauncher
    vlc
    ffmpeg

    # VPN
    proton-vpn
    proton-vpn-cli

    inputs.zennotes.packages.${pkgs.stdenv.hostPlatform.system}.zennotes-desktop
  ];

  programs.bash.enable = true;
  programs.git.enable = true;
}
