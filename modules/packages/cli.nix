{self, ...}: {
  unify.home = {pkgs, ...}: let
    packages = self.packages.${pkgs.stdenv.hostPlatform.system};
    # mvim is the everyday editor (`nvim`, `vi`); see modules/meta/nvim.nix.
    nvim = packages.mvim;
  in {
    home.packages = with pkgs; [
      bc
      btop
      choose
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
      prek
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
