{
  description = "Reexports some utils and implements flatpak-manager";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nix-lib-extra.url = "github:GustavoPeredo/nix-lib-extra";
  outputs = { self, nixpkgs, nix-lib-extra }:
    let
      inherit (nixpkgs.lib.attrsets) filterAttrs genAttrs mapAttrs;
      apkgs = import nixpkgs { 
        overlays = [ 
          (self: super: {
            lib = nix-lib-extra.lib;
          })
        ];
      };
      systems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (system: import ./default.nix {
        pkgs = apkgs;
      });
      
      overlays = import ./overlays { nix-lib-extra = nix-lib-extra.lib ;};
      nixosModules = mapAttrs (name: path: import path) (import ./modules);
    };
}
