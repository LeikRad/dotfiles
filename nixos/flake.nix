{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
	url = "github:nix-community/home-manager";
       	inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    {
    nixosConfigurations = {
      vm = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/vm/configuration.nix
        ];
      };
      legion = nixpkgs.lib.nixosSystem {
	specialArgs = { inherit inputs; };
	modules = [
	  ./hosts/legion/configuration.nix
	];
      };
    };
  };
}
