{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../modules/home-manager/vscode/vscode.nix
    ../../modules/home-manager/zed/zed.nix
    ../../modules/home-manager/git/git.nix
    ../../modules/home-manager/discord/discord.nix
    ../../modules/home-manager/moonlight/moonlight.nix
    ../../modules/home-manager/spotify/spotify.nix
    ../../modules/home-manager/figma/figma.nix
    ../../modules/home-manager/ghostty/ghostty.nix
    ../../modules/home-manager/obsidian/obsidian.nix
    ../../modules/home-manager/modrinth-app/modrinth-app.nix
    ../../modules/home-manager/sh/sh.nix
    ../../modules/home-manager/cursor/cursor.nix
    ../../modules/home-manager/direnv/direnv.nix
    ../../modules/home-manager/umbriel/umbriel.nix
    inputs.noctalia.homeModules.default
  ];

  home.username = "leikrad";
  home.homeDirectory = "/home/leikrad";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.claude-code
    pkgs.vagrant
    pkgs.libreoffice-qt

    # Umbriel's (and Hyprland's) packaged default config spawns kitty as
    # the terminal keybind.
    pkgs.kitty

    # Astal/AGS: just the runtime + scaffolding CLI, no starter widget —
    # `ags init` from here to start writing your own.
    pkgs.ags
    pkgs.astal.gjs

    # Fabric: the Python framework itself plus the GTK/GI runtime it needs
    # at import time, mirroring Fabric's own devShell dependency list
    # (github:Fabric-Development/fabric flake.nix) so `python3 -c "import
    # fabric"` and any GTK widgets you write actually work, without a
    # starter widget of our own.
    (pkgs.python3.withPackages (ps: [
      inputs.fabric.packages.${pkgs.stdenv.hostPlatform.system}.default
      ps.pygobject3
      ps.pycairo
      ps.loguru
      ps.psutil
    ]))
    pkgs.gtk3
    pkgs.gtk-layer-shell
    pkgs.cairo
    pkgs.gobject-introspection
    pkgs.libdbusmenu-gtk3
    pkgs.gdk-pixbuf
    pkgs.gnome-bluetooth
    pkgs.cinnamon-desktop

    # Logs one CSV row per `wm-bench <compositor> <idle|active>` call to
    # ~/wm-bench.csv: RSS + CPU% summed over the current graphical session's
    # systemd scope (compositor-agnostic), plus instantaneous battery draw.
    # "Ease of configuration" has no meter, so there's a trailing `notes`
    # column left blank for filling in by hand.
    (pkgs.writeShellScriptBin "wm-bench" ''
      set -euo pipefail

      name="''${1:?usage: wm-bench <compositor-name> <idle|active>}"
      state="''${2:?usage: wm-bench <compositor-name> <idle|active>}"

      csv="$HOME/wm-bench.csv"
      if [ ! -f "$csv" ]; then
        echo "timestamp,compositor,state,rss_kb,cpu_pct,power_uw,notes" > "$csv"
      fi

      sid="''${XDG_SESSION_ID:-$(${pkgs.systemd}/bin/loginctl session-status 2>/dev/null | head -1 | awk '{print $1}')}"
      scope="$(${pkgs.systemd}/bin/loginctl show-session "$sid" -p Scope --value 2>/dev/null || true)"
      cgroup="/sys/fs/cgroup/user.slice/user-$(id -u).slice/$scope"

      # ps -o %cpu is a lifetime average since each process started, so a
      # short burst of "active" use barely moves it. Sample summed CPU
      # ticks across the session's cgroup twice, 1s apart, and compute the
      # actual rate over that window instead.
      sample() {
        rss=0
        ticks=0
        if [ -n "$scope" ] && [ -r "$cgroup/cgroup.procs" ]; then
          while read -r pid; do
            [ -r "/proc/$pid/status" ] && [ -r "/proc/$pid/stat" ] || continue
            pid_rss=$(awk '/VmRSS/{print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
            rest="$(cat "/proc/$pid/stat" 2>/dev/null)"
            rest="''${rest##*) }"
            pid_ticks=$(awk '{print $12 + $13}' <<< "$rest")
            rss=$((rss + ''${pid_rss:-0}))
            ticks=$((ticks + ''${pid_ticks:-0}))
          done < "$cgroup/cgroup.procs"
        fi
        echo "$rss $ticks"
      }

      read -r rss0 ticks0 <<< "$(sample)"
      sleep 1
      read -r rss_kb ticks1 <<< "$(sample)"

      clk_tck=$(getconf CLK_TCK)
      cpu_pct=$(awk -v t0="$ticks0" -v t1="$ticks1" -v hz="$clk_tck" 'BEGIN{printf "%.1f", (t1-t0)/hz*100}')

      power_uw="NA"
      bat="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1 || true)"
      if [ -n "$bat" ] && [ -r "$bat/power_now" ]; then
        power_uw="$(cat "$bat/power_now")"
      fi

      echo "$(date -Iseconds),$name,$state,$rss_kb,$cpu_pct,$power_uw," >> "$csv"
      echo "Logged: $name/$state — RSS ''${rss_kb}KB, CPU ''${cpu_pct}% (1s sample), power ''${power_uw}uW -> $csv"
    '')
  ];

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Runs as a systemd user service tied to graphical-session.target, so it
  # autostarts the same way under both Hyprland and Umbriel without either
  # compositor's config needing to spawn it.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };
  
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/leikrad/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
