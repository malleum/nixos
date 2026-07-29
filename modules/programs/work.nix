{inputs, ...}: {
  unify.modules.wrk.home = {pkgs, ...}: {
    programs.zsh.initContent = ''
      typeset -gA _zsh_abbrs
      _zsh_abbrs=(
        stag 'STAGING_BRANCH=$(git branch --show-current)'
        prod 'VS_RUN_PROD=1'
      )
      _expand_abbr() {
        local word=''${LBUFFER##* }
        if [[ -n ''${_zsh_abbrs[$word]} ]]; then
          LBUFFER=''${LBUFFER%$word}''${_zsh_abbrs[$word]}
        fi
        zle self-insert
      }
      zle -N _expand_abbr
      bindkey ' ' _expand_abbr
      bindkey -M isearch ' ' self-insert
    '';

    home.packages = with pkgs; [
      awscli2
      glab
      gpclient # GlobalProtect VPN
      inputs.fix-python.packages.${pkgs.stdenv.hostPlatform.system}.default
      openvpn
      uv
    ];
  };
}
