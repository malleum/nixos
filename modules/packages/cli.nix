{self, ...}: {
  unify.home = {
    lib,
    pkgs,
    nixosConfig,
    ...
  }: let
    packages = self.packages.${pkgs.stdenv.hostPlatform.system};
    # mvim is the everyday editor (`nvim`, `vi`); see modules/meta/nvim.nix.
    nvim = packages.mvim;
    # The full nixvim build, only where the host opts in (the `dev` module).
    # A separate name so it can sit next to mvim, whose binaries are nvim/vi.
    nixvim = pkgs.writeShellScriptBin "nixvim" ''
      exec ${packages.nvim}/bin/nvim "$@"
    '';
    cls = packages.cls;
  in {
    home.packages =
      lib.optional nixosConfig.local.fullNvim nixvim
      ++ (with pkgs; [
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
      ]);
  };
}
