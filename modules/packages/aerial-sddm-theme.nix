{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "aerial-sddm-theme";
  version = "eeede25";
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/aerial-sddm-theme
  '';
  src = fetchFromGitHub {
    owner = "speedster33";
    repo = "aerial-sddm-theme";
    rev = "eeede259af5f1cc46132f15e01edb20280b41101";
    sha256 = "vwLXv2Tgm15L4mxVjgts2wcQZ1RetEke36nLzbfUIa0=";
  };
}
