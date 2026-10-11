# System-level services + minimal recovery tools.
# Rule: if it doesn't need root / hardware / boot integration -> home-manager.
{ pkgs, ... }:

{
  time.timeZone = "Europe/Tallinn";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "et_EE.UTF-8";
    LC_IDENTIFICATION = "et_EE.UTF-8";
    LC_MEASUREMENT = "et_EE.UTF-8";
    LC_MONETARY = "et_EE.UTF-8";
    LC_NAME = "et_EE.UTF-8";
    LC_NUMERIC = "et_EE.UTF-8";
    LC_PAPER = "et_EE.UTF-8";
    LC_TELEPHONE = "et_EE.UTF-8";
    LC_TIME = "et_EE.UTF-8";
  };

  programs.nix-ld.enable = true;

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      log-driver = "journald";
      storage-driver = "overlay2";
      iptables = true;
    };
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # Recovery set only. Everything else is in home-manager so that
  # adding a dev tool doesn't re-evaluate/rebuild the OS.
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    unzip
    wl-clipboard
    iptables
    nftables
    lm_sensors
    coreutils
  ];
}
