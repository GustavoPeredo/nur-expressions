nix-lib-extra:
{
  readFiles = nix-lib-extra.readFiles;

  recursiveMergeAttrs = nix-lib-extra.recursiveMergeAttrs;
  # Add your library functions here
  #
  # hexint = x: hexvals.${toLower x};
}
