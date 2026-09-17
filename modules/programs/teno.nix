# teno has no binary cache, so it is compiled locally. Like jay and iamb in
# meta/source-builds.nix, it only goes on hosts that opt into source builds
# with `src`; minimus and minoris keep just tmux.
{inputs, ...}: {
  unify.modules.src.home = {config, ...}: let
    color = key: default:
      if config ? stylix && config.stylix ? base16Scheme && config.stylix.base16Scheme ? ${key}
      then "#${config.stylix.base16Scheme.${key}}"
      else "#${default}";
  in {
    imports = [inputs.teno.homeManagerModules.default];

    # Runs alongside tmux until it has proven itself; tmux stays installed.
    programs.teno = {
      enable = true;
      colors = {
        bg = color "base00" "12151a";
        fg = color "base05" "c5cbd3";
        accent = color "base0D" "5e9de5";
        accent-fg = color "base00" "12151a";
        muted = color "base02" "3a424d";
        highlight = color "base0C" "88c0d0";
      };
      # Same reasoning as tmux.nix: a foreground daemon (Type=exec) tied to
      # the jay session. The restore happens inside the daemon, so nothing
      # blocks the unit from becoming active.
      systemd.target = "jay-session.target";
    };
  };
}
