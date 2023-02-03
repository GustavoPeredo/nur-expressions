{ lib, ... }:

{
  readFiles = lib.readFiles;

  recursiveMergeAttrs = lib.recursiveMergeAttrs;
  # Add your library functions here
  #
  # hexint = x: hexvals.${toLower x};
}
