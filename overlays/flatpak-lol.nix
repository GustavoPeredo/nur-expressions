self: super:
let
  pkgs = import ./pkgs.nix { inherit self; };
{
  flatpak-lol = pkgs.flatpak-lol;
}