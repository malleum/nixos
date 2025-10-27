{
  unify.nixos = {config, ...}: {
    programs = {
      nh = {
        enable = true;
        clean.enable = true;
        flake = "${config.configHome}/nixos";
      };
    };
  };
}
