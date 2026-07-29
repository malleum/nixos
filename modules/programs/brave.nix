{
  # Despite the name, programs.chromium is NixOS' Chromium-*family* policy
  # module: it writes /etc/brave/policies/managed/extra.json as well as the
  # chromium one, and Brave reads both. So this is not chromium doing Brave's
  # job -- it is the correct place for these, and hand-rolling an
  # environment.etc entry instead would also drop stylix, which injects
  # BrowserThemeColor through extraOpts.
  unify.modules.gui.nixos = {
    programs.chromium = {
      enable = true;
      extraOpts = {
        "BraveVPNDisabled" = true;
        "BraveWalletDisabled" = true;
      };
    };
  };

  unify.modules.gui.home = {pkgs, ...}: {
    programs.chromium = {
      enable = true;
      # pkgs.brave lost its `.override` in this nixpkgs (double-callPackage
      # currying in brave/default.nix drops overridability), which breaks
      # home-manager's chromium module (it does cfg.package.override
      # {commandLineArgs=...} whenever commandLineArgs != []). Bake the flags
      # into the binary ourselves via a wrapper instead, and leave
      # commandLineArgs empty so home-manager takes the no-override branch.
      package = pkgs.symlinkJoin {
        name = "brave-wrapped";
        paths = [pkgs.brave];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/brave --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland --password-store=basic"
        '';
      };
      commandLineArgs = [];
      extensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark reader
        "hfjbmagddngcpeloejdejnfgbamkjaeg" # vimium c
        "nacjakoppgmdcpemlfnfegmlhipddanj" # pdf vimium c
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      ];
    };
  };
}
