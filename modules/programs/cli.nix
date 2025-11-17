{
  unify.home =
    { pkgs, ... }:
    {
      programs = {
        zoxide.enable = true;
        eza = {
          enable = true;
          icons = "auto";
        };
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };

      home = {
        packages = with pkgs; [ grc ];

        sessionVariables = {
          MANPAGER = "sh -c 'col -bx | ${pkgs.grc}/bin/grc --colour -s | ${pkgs.less}/bin/less -R'";
        };
      };
    };
}
