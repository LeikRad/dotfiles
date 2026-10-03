{
    pkgs,
    lib,
    ...
}: {
    home.packages = [
        pkgs.obs-studio
    ];
}
