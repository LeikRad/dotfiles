project('astal-shell', 'vala', 'c')

# Add an astal-<lib>-0.1 dependency here (and the matching pkgs.astal.<lib>
# in flake.nix) when you start using another service: network, tray,
# wireplumber, mpris, notifd, bluetooth, ...
deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('gtk+-3.0'),
  dependency('astal-io-0.1'),
  dependency('astal-3.0'),
  dependency('astal-hyprland-0.1'),
  dependency('astal-battery-0.1'),
]

executable(
  'astal-shell',
  files(
    'src/app.vala',
    'src/style.vala',
    'src/bar.vala',
    'src/widgets/workspaces.vala',
    'src/widgets/clock.vala',
    'src/widgets/battery.vala',
  ),
  dependencies: deps,
  install: true,
)
