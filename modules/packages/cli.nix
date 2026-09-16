{self, ...}: {
  unify.home = {pkgs, ...}: let
    nvim = self.packages.${pkgs.stdenv.hostPlatform.system}.mvim;
    cls = self.packages.${pkgs.stdenv.hostPlatform.system}.cls;
  in {
    home.packages = with pkgs; [
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
