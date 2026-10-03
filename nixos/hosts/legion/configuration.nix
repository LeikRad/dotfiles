# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      useOSProber = true;
      efiSupport = true;
      device = "nodev";
    };
  };

  # Compressed RAM-backed swap. There is no disk swap device (see
  # hardware-configuration.nix), which left systemd-oomd unable to detect
  # memory pressure ("No swap; memory pressure usage will be degraded") and
  # long gaming sessions (Minecraft, etc.) ending in hard freezes once RAM
  # filled up with nowhere for the kernel to reclaim pages to.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  networking.hostName = "legion"; # Define your hostname.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";

  # Select internationalisation properties.
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

  virtualisation.docker = {
    enable = true;
    # Default bridge subnet (172.17.0.0/16) collides with some real-world
    # networks (e.g. mobile hotspots), breaking routing when joined. Move it
    # out of the way.
    daemon.settings = {
      bip = "172.30.0.1/16";
    };
  };

  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # GNOME stays enabled as the known-good fallback session alongside Hyprland.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.excludePackages = [
    pkgs.xterm
  ];

  # Daily driver, with Astal (Vala) for the shell widgets.
  programs.hyprland.enable = true;

  # Hybrid graphics: AMD iGPU drives the display by default (low power).
  # The NVIDIA dGPU stays runtime-suspended until something is explicitly
  # offloaded to it (GNOME's "Launch using Discrete Graphics GPU", a game
  # launcher's GPU toggle, or `nvidia-offload <cmd>`), then it powers back
  # down once that process exits.
  services.switcherooControl.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # needed for Steam and other 32-bit games/libs
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.tailscale.enable = true;
  services.netbird.enable = true;

  # Remote desktop for controlling this machine from Windows (Moonlight
  # client) over the local network. capSysAdmin is required for DRM/KMS
  # screen capture under Hyprland (wlroots-based Wayland).
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Lets prebuilt/generic-Linux dynamically-linked binaries run unmodified
  # (e.g. Zed's claude-acp npm package bundles its own `claude` binary that
  # isn't patched for NixOS and fails with "cannot run dynamically linked
  # executables" without this).
  programs.nix-ld.enable = true;

  environment.systemPackages = [
    pkgs.brightnessctl
    pkgs.powertop
    pkgs.openssl
    pkgs.steam-run # FHS sandbox for native Linux games that ship plain dynamically-linked binaries (e.g. Synergism)
    (pkgs.writeShellScriptBin "synergism-run" ''
      # Synergism's Electron build needs NSS/GTK libs that steam-run's
      # default FHS sandbox doesn't ship, on top of that sandbox itself.
      # It also crashes under native Wayland/Ozone (EGL context loss), so
      # it's forced onto XWayland instead.
      export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
        pkgs.nspr
        pkgs.nss
        pkgs.at-spi2-core
        pkgs.gtk3
        pkgs.libxcomposite
      ]}:$LD_LIBRARY_PATH"
      exec ${pkgs.steam-run}/bin/steam-run "$@" --ozone-platform=x11
    '')
  ];

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.leikrad = {
    isNormalUser = true;
    description = "LeikRad";
    extraGroups = [ "networkmanager" "wheel" "docker" "vboxusers" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      jdk
      jdk25
    #  thunderbird
    ];
  };
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "leikrad" = import ./home.nix;
    };
  };

  programs.zsh.enable = true;
  programs.command-not-found.enable = false;

  # Install firefox.
  programs.firefox.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
