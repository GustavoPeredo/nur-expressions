nix-lib-extra:
self: super:
{
  lib = super.lib // (import ../lib/default.nix nix-lib-extra);
}