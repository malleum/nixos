{
  unify.nixos = {hostConfig, ...}: {
    environment.variables = {
      NH_NO_CHECKS = 1;
    };

    programs = {
      nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep 2 --keep-since 3d";
        };
        flake = hostConfig.flakePath;
      };
    };
  };

  unify.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      nix-output-monitor
      nvd
    ];
  };
}
