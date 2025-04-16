{pkgs, ...}: let
in
  pkgs.stdenv.mkDerivation {
    name = "iogii";
    src = builtins.fetchurl {
      url = "https://golfscript.com/iogii/iogii-0.3-beta";
      sha256 = "sha256:1ans49j2mg9319xhag8saiv1zsk8g716l6ajvn0s1kshkkq1dc0l";
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
