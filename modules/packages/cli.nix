{self, ...}: {
  unify.home = {
    pkgs,
    hostConfig,
    ...
  }: let
    variant =
      if hostConfig.name == "minimus"
      then "mvim"
      else "nvim";
    nvim = self.packages.${pkgs.stdenv.hostPlatform.system}.${variant};
  in {
    home.packages = with pkgs; [
      bat
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
