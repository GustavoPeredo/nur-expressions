lib:
self: super:
{
  lib = super.lib // (import ../lib/default.nix { lib = lib; });
}