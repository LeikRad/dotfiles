{
    pkgs,
    lib,
    ...
}: {
    home.packages = [
        pkgs.modrinth-app
    ];
}
