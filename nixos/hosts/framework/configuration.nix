{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.catppuccin.nixosModules.catppuccin
    ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
  };
  # Animated boot splash: Framework's own firmware "follow the penguin"
  # animation, reimplemented as a Plymouth script theme.
  # https://github.com/ygurin/framework-penguin
  boot.plymouth = {
    enable = true;
    theme = lib.mkForce "framework-penguin";
    themePackages = [
      (pkgs.stdenvNoCC.mkDerivation {
        pname = "framework-penguin-plymouth";
        version = "unstable-2026-09-30";
        src = pkgs.fetchFromGitHub {
          owner = "ygurin";
          repo = "framework-penguin";
          rev = "13c0295d65b0ce45116decdc69fadf4679c7d9a7";
          sha256 = "0hrxnq9yjx9layplqn2s4jd91cq3rgzcdi983p4pfnbj51kx9dqs";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/share/plymouth/themes/framework-penguin
          cp -r $src/* $out/share/plymouth/themes/framework-penguin/
          # Upstream hardcodes /usr/share/plymouth/themes/framework-penguin,
          # which doesn't exist on NixOS (no /usr/share, and the script
          # plugin resolves ScriptFile against its own cwd, not relative to
          # the .plymouth file, so a bare "." doesn't work either). NixOS's
          # equivalent stable path, present both pre- and post-switch-root,
          # is /etc/plymouth/themes/<name>.
          substituteInPlace $out/share/plymouth/themes/framework-penguin/framework-penguin.plymouth \
            --replace-fail "/usr/share/plymouth/themes/framework-penguin" "/etc/plymouth/themes/framework-penguin"

          # watermark.png is a leftover Fedora logo from upstream. Hide it
          # (keeping the sprite itself real, not null, so refresh_callback's
          # SetX/SetY calls on it don't error) rather than yanking the whole
          # logo block out and risking a null-reference script error.
          substituteInPlace $out/share/plymouth/themes/framework-penguin/framework-penguin.script \
            --replace-fail 'logo.sprite.SetZ(Z_UI);' 'logo.sprite.SetZ(Z_UI);
logo.sprite.SetOpacity(0);'
        '';
      })
    ];
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

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

  # "splash" alone isn't enough for the Plymouth splash to actually own the
  # screen — without "quiet", systemd still prints its own unit status lines
  # ("Starting X...") straight to the console over/instead of it.
  boot.kernelParams = [ "quiet" ];

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

  # Vagrant (Kali VM) via libvirt/KVM: in-tree kvm_amd module, so unlike
  # VirtualBox's vboxdrv it loads fine under Secure Boot/lockdown.
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

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
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "kvm" ];
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
