{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

  # Btrfs mount options (merged with hardware-configuration.nix)
  fileSystems."/".options = [ "compress=zstd" "noatime" ];
  fileSystems."/home".options = [ "compress=zstd" "noatime" ];
  fileSystems."/nix".options = [ "compress=zstd" "noatime" ];
  fileSystems."/var/log".options = [ "compress=zstd" "noatime" ];
  fileSystems."/swap".options = [ "noatime" ];

  # Access Permissions
  fileSystems."/boot".options = lib.mkForce [ "fmask=0077" "dmask=0077" ];
  fileSystems."/efi".options = lib.mkForce [ "fmask=0077" "dmask=0077" ];

  # Boot: systemd-boot's loader lives on Windows' shared ESP, kernels on
  # XBOOTLDR. Lanzaboote (Secure Boot) replaces systemd-boot's own activation
  # but still reads xbootldrMountPoint/efiSysMountPoint below for where to
  # place its signed stubs and boot entries.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Swap. Hibernation is disabled below (see systemd.sleep.settings) after
  # hitting unresolved AMD platform-firmware instability on S4 resume/entry
  # (Framework 13 Ryzen AI 300 / Krackan) — the swapfile stays as plain swap
  # headroom regardless.
  swapDevices = [ { device = "/swap/swapfile"; } ];
  zramSwap.enable = true;

  # Hibernate is unreliable on this hardware right now (AMD AGESA/PMFW sync
  # flood on resume, and a separate unresolved abort during S4 entry itself)
  # — refuse it outright rather than risk it half-triggering.
  systemd.sleep.settings.Sleep = {
    AllowHibernation = false;
    AllowSuspendThenHibernate = false;
    AllowHybridSleep = false;
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };

  # Maintenance and firmware
  services.btrfs.autoScrub.enable = true;
  services.fwupd.enable = true;

  networking.hostName = "framework";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT = "pt_PT.UTF-8";
    LC_MONETARY = "pt_PT.UTF-8";
    LC_NAME = "pt_PT.UTF-8";
    LC_NUMERIC = "pt_PT.UTF-8";
    LC_PAPER = "pt_PT.UTF-8";
    LC_TELEPHONE = "pt_PT.UTF-8";
    LC_TIME = "pt_PT.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Desktop: GNOME stays enabled as the known-good fallback session
  # alongside Hyprland.
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];

  # Daily driver, with AGS/Astal for the shell widgets.
  programs.hyprland.enable = true;

  hardware.graphics.enable32Bit = true; # needed for Steam and other 32-bit games/libs

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.leikrad = {
    isNormalUser = true;
    description = "LeikRad";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "leikrad" = import ./home.nix;
    };
  };

  programs.firefox.enable = true;
  programs.zsh.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ git vim wget sbctl ];

  system.stateVersion = "26.05";
}
