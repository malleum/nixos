{
  unify.nixos = {hostConfig, ...}: {
    programs = {
      nh = {
        enable = true;
        clean.enable = true;
        flake = "${hostConfig.user.configHome}/nixos";
      };
    };
  };

  unify.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      nix-prefetch-github
      nix-output-monitor
      nixos-shell
      nvd
    ];
  };
}
