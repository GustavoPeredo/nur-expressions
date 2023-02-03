{ nix-lib-extra, ... }:
{
    lib = import ./lib.nix nix-lib-extra;
    flatpak-lol = import ./flatpak-lol.nix;
}