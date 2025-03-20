{
pkgs,
lib,
config,
...
}: {
  options.gnome = {
    enable = lib.mkEnableOption "gnome";
  };

  config = lib.mkIf config.gnome.enable {
    environment = {
      systemPackages = with pkgs; [ ];

      gnome.excludePackages = with pkgs; [
        gnome-console
        gnome-photos
        gnome-tour
        gnome-connections
        epiphany
        xterm
      ];
    };

    services.xserver = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
