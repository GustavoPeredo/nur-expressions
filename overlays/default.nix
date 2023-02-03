{ lib, ... }:
{
    lib = import ./lib.nix { lib = lib; };
}