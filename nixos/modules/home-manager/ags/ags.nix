{
    pkgs,
    lib,
    ...
}: {
    home.packages = [
        # Astal/AGS: just the runtime + scaffolding CLI, no starter widget —
        # `ags init` from here to start writing your own.
        pkgs.ags
        pkgs.astal.gjs
        pkgs.gtk3
        pkgs.gtk-layer-shell
        pkgs.cairo
        pkgs.gobject-introspection
        pkgs.libdbusmenu-gtk3
        pkgs.gdk-pixbuf
        pkgs.gnome-bluetooth
        pkgs.cinnamon-desktop

        # Hyprland's packaged default config spawns kitty as the terminal keybind.
        pkgs.kitty
    ];
}
