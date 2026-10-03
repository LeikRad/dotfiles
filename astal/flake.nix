{
  description = "Astal (Vala) desktop shell for Hyprland";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "astal-shell";
        version = "0.1.0";
        src = ./.;

        nativeBuildInputs = with pkgs; [
          meson
          ninja
          pkg-config
          vala
          gobject-introspection
          wrapGAppsHook3
        ];

        buildInputs = with pkgs; [
          glib
          gtk3
          astal.io
          astal.astal3
          astal.hyprland
          astal.battery
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [ self.packages.${system}.default ];
        packages = [ pkgs.vala-language-server ];
      };
    };
}
