{
    pkgs,
    lib,
    ...
}: {
    programs.ghostty = {
        enable = true;
        settings = {
            theme = "catppuccin-mocha";
            font-family = "JetBrainsMono Nerd Font";
        };
    };

    home.sessionVariables.TERMINAL = "ghostty";
}
