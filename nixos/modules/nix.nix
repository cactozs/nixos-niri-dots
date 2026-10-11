# Nix itself: caches, parallelism, gc, helpers for fast rebuilds.
{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    builders-use-substitutes = true;
    max-jobs = "auto";
    cores = 0;
    fallback = true;
    warn-dirty = false;
    # cache.nixos.org уже в дефолтах nixpkgs, дописываем только community-cache
    # (списки в nix.settings складываются с дефолтными, а не заменяют их).
    substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSU6n1BdtYrXbc3Erm3Y/HLi93RGU="
    ];
    trusted-users = [ "root" "@wheel" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  nixpkgs.config.allowUnfree = true;

  # Fast rebuild frontend: `nh os switch` instead of raw nixos-rebuild.
  # Auto-clean timer lives in nix.gc (below), nh clean stays manual via `sys-clean`
  # to avoid two GC timers fighting.
  programs.nh = {
    enable = true;
    clean.enable = false;
    flake = "/home/cactoz/nix-temp";
  };

  environment.systemPackages = with pkgs; [
    nh
    nix-output-monitor
    nvd
    comma
  ];

  # Don't let /boot fill up with generations.
  boot.loader.systemd-boot.configurationLimit = 10;

  # Imperative-like shortcuts. Declarative config stays source of truth,
  # but day-to-day feels like pacman/apt:
  #
  #   sys-switch          rebuild+activate current flake (fast, cached)
  #   sys-update          update nixpkgs input + rebuild
  #   sys-test / sys-boot test without adding boot entry / add boot entry only
  #   sys-diff            what would change: nvd diff /run/current-system result
  #   sys-rollback        revert to previous generation
  #   sys-clean           delete generations older than 14d, keep last 5
  #   pkg-add <pkg>       nix profile install nixpkgs#<pkg>  (NO rebuild, NO sudo)
  #   pkg-del <pkg>       nix profile remove <pkg>
  #   pkg-list            nix profile list
  #   try <pkg> <cmd..>   nix shell nixpkgs#<pkg> -c <cmd> (e.g. try helix hx)
  environment.shellAliases = {
    sys-switch = "nh os switch /home/cactoz/nix-temp";
    sys-test = "nh os test /home/cactoz/nix-temp";
    sys-boot = "nh os boot /home/cactoz/nix-temp";
    sys-update = "nh os switch --update /home/cactoz/nix-temp";
    sys-diff = "nvd diff /run/current-system result";
    sys-rollback = "nh os rollback";
    sys-clean = "nh clean all --keep 5 --keep-since 14d";
    sys-search = "nix search nixpkgs";
    home-switch = "nh home switch /home/cactoz/nix-temp";
    pkg-add = "nix profile install";
    pkg-del = "nix profile remove";
    pkg-list = "nix profile list";
    pkg-up = "nix profile upgrade --all";
  };

  programs.bash.interactiveShellInit = ''
    # try <pkg> [args...] -> nix run without installing, e.g. `try yazi`
    try() { nix run nixpkgs#"''${1:?usage: try <pkg> [args...]}" -- "''${@:2}"; }
    # pkgshell <pkg...> -> temp shell with packages, e.g. `pkgshell jq ffmpeg`
    pkgshell() { nix shell $(printf 'nixpkgs#%s ' "$@"); }
    # , <pkg> [args...] via comma-nix
    export NIX_COMMA_EXPERIMENTAL=1
  '';
}
