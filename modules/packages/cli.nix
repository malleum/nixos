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
    # The plugin-free build is always reachable as `mvim`, whichever one `nvim` is.
    mvim = pkgs.writeShellScriptBin "mvim" ''
      exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.mvim}/bin/nvim "$@"
    '';
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
      mvim
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
