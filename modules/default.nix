{
  flatpak = ./flatpak.nix;
  __functionArgs = { };
  __functor = self: { ... }: {
    imports = with self; [
      flatpak
    ];
  };
}
