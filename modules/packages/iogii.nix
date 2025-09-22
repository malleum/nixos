{pkgs, ...}: let
in
  pkgs.stdenv.mkDerivation {
    name = "iogii";
    src = builtins.fetchurl {
      url = "https://golfscript.com/iogii/iogii-1.1";
      sha256 = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    };
    buildInputs = [pkgs.ruby];
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
  }
