{self, ...}: {
  unify.home = {
    pkgs,
    nixosConfig,
    ...
  }: let
    # mvim unless the host takes `dev`; see modules/meta/nvim.nix.
    variant =
      if nixosConfig.local.fullNvim
      then "nvim"
      else "mvim";
    nvim = self.packages.${pkgs.stdenv.hostPlatform.system}.${variant};
    cls = self.packages.${pkgs.stdenv.hostPlatform.system}.cls;
  in {
    home.packages = with pkgs; [
      bat
      bc
      btop
      choose
      cls
      fastfetch
      fd
      file
      fzf
      htop
      jq
      killall
      ltrace
      nitch
      nmap
      nvim
      ouch
      rip2
      ripgrep
      sd
      tldr
      universal-ctags
      wget
      xan
    ];
  };
}
