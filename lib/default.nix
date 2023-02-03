{ pkgs, ... }:

with pkgs; {
  readFiles = readFiles;

  recursiveMergeAttrs = recursiveMergeAttrs;
  # Add your library functions here
  #
  # hexint = x: hexvals.${toLower x};
}
