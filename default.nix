let 
  haskellNix = import (builtins.fetchTarball https://github.com/input-output-hk/haskell.nix/archive/master.tar.gz) {};
  nixpkgsSrc = haskellNix.sources.nixpkgs-1909;
  nixpkgsArgs = haskellNix.nixpkgsArgs // {
    overlays = haskellNix.nixpkgsArgs.overlays ++ depMappings;
  };
  depMappings = [
    (self: super: {
      EGL = self.libGL.dev;
      GLESv2 = self.libGL.dev;
    })
  ];
in
{ pkgs ? import nixpkgsSrc nixpkgsArgs
}:
pkgs.haskell-nix.stackProject {
  src = pkgs.haskell-nix.haskellLib.cleanGit { src = ./.; };
}