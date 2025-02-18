{
  stdenv,
  ruby,
}: let
in
  stdenv.mkDerivation {
    name = "iogii";
    src = builtins.fetchurl {
      url = "https://golfscript.com/iogii/iogii-0.2-alpha";
      sha256 = "sha256-c1yEN23fG5SePVS4wXoiiUnyBS4K4La3GBYeopFJ97Q=";
    };
    buildInputs = [ruby];
    unpackPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,share/iogii}
      cp $src $out/share/iogii/iogii
      bin=$out/bin/iogii
      cat > $bin <<EOF
          #!/bin/sh -e
          exec ${ruby}/bin/ruby $out/share/iogii/iogii "\$@"
      EOF
      chmod +x $bin
    '';
  }
