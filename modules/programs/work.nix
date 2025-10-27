{
  unify.modules.wok.home = {pkgs, ...}: {
    programs.fish.shellInit = ''
      abbr -a stag "STAGING_BRANCH=(git branch --show-current)"
      abbr -a prod 'VS_RUN_PROD=1'
    '';

    home.packages = with pkgs; [
      awscli2
      openvpn
      uv
    ];
  };
}
