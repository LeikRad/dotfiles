{
    pkgs,
    lib,
    ...
}: {
    programs.starship = {
        enable = true;
        enableZshIntegration = true;
    };
}
