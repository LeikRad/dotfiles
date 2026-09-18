{
    pkgs,
    lib,
    ...
}: {
    # GNOME's dconf cursor-theme can end up pointing at a theme that isn't
    # actually installed (e.g. "breeze_cursors" from a stray gsettings
    # change), which makes the pointer render as a blank white box on
    # Wayland. Pin it to Adwaita, which is always present, and keep
    # XCURSOR_THEME/SIZE in sync for XWayland/non-GTK apps.
    home.pointerCursor = {
        enable = true;
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 24;
        gtk.enable = true;
        x11.enable = true;
    };

    dconf.settings."org/gnome/desktop/interface" = {
        cursor-theme = "Adwaita";
        cursor-size = 24;
    };
}
