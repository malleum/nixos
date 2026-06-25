{inputs, ...}: {
  unify.modules.gui.home = {pkgs, ...}: let
    iogii = pkgs.stdenv.mkDerivation {
      name = "iogii";
      src = builtins.fetchurl {
        url = "https://golfscript.com/iogii/iogii-1.2";
        sha256 = "sha256:1kgvr7jzayrcdm1wqk3pzl8lyjp317rk7vndwws3dl2x6ikbc2xn";
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
    };
    ago = inputs.ago.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    home.packages = with pkgs; [
      ago
      alejandra
      clang-tools
      gcc
      gnumake
      go
      iogii
      jdk
      lua
      nodejs
      python3
      typst
    ];
  };
}
