{
    pkgs,
    lib,
    ...
}: {
    home.packages = [
        # Astal (Vala): the shell itself lives in ~/dotfiles/astal and is built
        # with its own flake. This just provides the `astal` CLI for talking to
        # running instances (`astal -l`, `astal -i <name> <request>`, `astal -I`
        # for the GTK inspector).
        pkgs.astal.io

        # Hyprland's packaged default config spawns kitty as the terminal keybind.
        pkgs.kitty
    ];
}
