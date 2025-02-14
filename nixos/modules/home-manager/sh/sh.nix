{
    pkgs,
    config,
    lib,
    ...
}: let
    aliases = {
        "nix-rebuild" = "sudo nixos-rebuild switch --flake $HOME/dotfiles/nixos/#$HOSTNAME";
    };
in {
    options.shellAliases = with lib;
    mkOption {
        type = types.attrsOf types.str;
        default = {};
    };

    config.programs.fish = {
        shellAliases = aliases // config.shellAliases;
        enable = true;
        generateCompletions = true;
    };
}