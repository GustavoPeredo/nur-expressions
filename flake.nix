{
  description = "Reexports some utils and implements flatpak-manager";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nix-lib-extra.url = "github:GustavoPeredo/nix-lib-extra";
  outputs = { self, nixpkgs, nix-lib-extra }:
    let
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
      #homeModules = import ./hm-modules // {
      #  default = self.homeModules;
      #};
      packages = forAllSystems (system: import ./default.nix {
        pkgs = import nixpkgs { 
          inherit system; 
          overlays = [ (self: super: {
            readFiles = nix-lib-extra.lib.readFiles;
            recursiveMergeAttrs = nix-lib-extra.lib.recursiveMergeAttrs;
          })];
        };
      });
    };
}
