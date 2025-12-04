{
  outputs = { nixpkgs, ... }: {
    devShells.default = nixpkgs.lib.mkShell {
      packages = [
        (nixpkgs.python312.withPackages (ps: [
          ps.grpcio-tools
          ps.black
        ]))
      ];
    };
  };
}
