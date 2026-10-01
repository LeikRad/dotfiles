{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
	url = "github:nix-community/home-manager";
       	inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    # Using sarunint's fork/branch instead of upstream: upstream lanzaboote
    # doesn't yet support a split ESP + XBOOTLDR layout (needed for
    # framework's shared 200M Windows ESP + separate XBOOTLDR partition).
    # See https://github.com/nix-community/lanzaboote/pull/456 — switch back
    # to upstream once that merges.
    lanzaboote = {
      url = "github:sarunint/lanzaboote/xbootldr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    {
    nixosConfigurations = {
      legion = nixpkgs.lib.nixosSystem {
	specialArgs = { inherit inputs; };
	modules = [
	  ./hosts/legion/configuration.nix
	];
      };
      framework = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/framework/configuration.nix
        ];
      };
    };
  };
}
