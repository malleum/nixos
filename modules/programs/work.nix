{inputs, ...}: {
  unify.modules.wrk.home = {pkgs, ...}: {
    programs.fish.shellInit = ''
      abbr -a stag "STAGING_BRANCH=(git branch --show-current)"
      abbr -a prod 'VS_RUN_PROD=1'
    '';

    home.packages = with pkgs; [
      awscli2
      glab
      inputs.fix-python.packages.${pkgs.stdenv.hostPlatform.system}.default
      openvpn
      uv
    ];
  };
}
