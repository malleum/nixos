{
  unify.modules.gui.nixos = {
    programs.chromium = {
      enable = true;
      extraOpts = {
        "BraveVPNDisabled" = true;
        "BraveWalletDisabled" = true;
      };
    };
  };

  unify.modules.gui.home =
    { pkgs, ... }:
    {
      programs.chromium = {
        enable = true;
        package = pkgs.brave;
        commandLineArgs = [
          "--enable-features=UseOzonePlatform"
          "--ozone-platform=wayland"
          "--password-store=basic"
        ];
        extensions = [
          "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark reader
          "hfjbmagddngcpeloejdejnfgbamkjaeg" # vimium c
          "nacjakoppgmdcpemlfnfegmlhipddanj" # pdf vimium c
          "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        ];
      };
    };
}
