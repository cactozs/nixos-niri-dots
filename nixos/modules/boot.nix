# Bootloader + kernel. Default kernel (not _latest) = cache hits,
# hence much faster updates. Switch to _latest only if you need new HW support.
{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Was: pkgs.linuxPackages_latest. That rebuilds kernel + nvidia out-of-cache
  # on almost every unstable bump. Default tracks the tested kernel for the
  # release and is almost always prebuilt.
  boot.kernelPackages = pkgs.linuxPackages;

  boot.tmp.useTmpfs = true;

  boot.kernelParams = [
    "nvidia.NVreg_EnableGpuFirmware=0"
  ];
}
