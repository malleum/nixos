{
  unify.home =
    { pkgs, ... }:
    let
      iogii = pkgs.stdenv.mkDerivation {
        name = "iogii";
        src = builtins.fetchurl {
          url = "https://golfscript.com/iogii/iogii-1.1";
          sha256 = "sha256:0fv7myy1mcn9s5r46lbffqwhkkfb9p7582agbgp5c8zh3kdcmy5v";
        };
        buildInputs = [ pkgs.ruby ];
        unpackPhase = ":";
        installPhase = ''
          mkdir -p $out/{bin,share/iogii}
          cp $src $out/share/iogii/iogii
          bin=$out/bin/iogii
          cat > $bin <<EOF
              #!/bin/sh -e
              exec ${pkgs.ruby}/bin/ruby $out/share/iogii/iogii "\$@"
          EOF
          chmod +x $bin
        '';
      };
    in
    {
      home.packages = [ iogii ];
    };
}
