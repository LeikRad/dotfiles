{ config, pkgs, inputs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [
    inputs.catppuccin.homeModules.catppuccin
    ../../modules/home-manager/vscode/vscode.nix
    ../../modules/home-manager/zed/zed.nix
    ../../modules/home-manager/neovim/neovim.nix
    ../../modules/home-manager/git/git.nix
    ../../modules/home-manager/discord/discord.nix
    ../../modules/home-manager/moonlight/moonlight.nix
    ../../modules/home-manager/spotify/spotify.nix
    ../../modules/home-manager/ghostty/ghostty.nix
    ../../modules/home-manager/obsidian/obsidian.nix
    ../../modules/home-manager/modrinth-app/modrinth-app.nix
    ../../modules/home-manager/sh/sh.nix
    ../../modules/home-manager/cursor/cursor.nix
    ../../modules/home-manager/direnv/direnv.nix
    ../../modules/home-manager/astal/astal.nix
    ../../modules/home-manager/starship/starship.nix
    ../../modules/home-manager/eza/eza.nix
    ../../modules/home-manager/zoxide/zoxide.nix
    ../../modules/home-manager/fzf/fzf.nix
    ../../modules/home-manager/goose/goose.nix
    ../../modules/home-manager/obs-studio/obs-studio.nix
    ../../modules/home-manager/fastfetch/fastfetch.nix
  ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
  };

  home.username = "leikrad";
  home.homeDirectory = "/home/leikrad";

  home.stateVersion = "26.05";

  home.packages = [
    pkgs.claude-code
    pkgs.vagrant
  ];

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;
}
