{
  unify.nixos = {
    pkgs,
    hostConfig,
    ...
  }: {
    programs.fish.enable = true;
    environment = {
      shells = [pkgs.fish];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        TERMINAL = "foot";
        BROWSER = hostConfig.user.browser;
        BROWSER2 = hostConfig.user.browser2;
      };
    };

    users.defaultUserShell = pkgs.fish;
  };

  unify.home = {pkgs, ...}: {
    programs = {
      fish = {
        enable = true;
        shellInit = ''
          function fish_command_not_found
              echo skill issue: $argv[1]
          end

          set -g fish_greeting ""

          fish_vi_key_bindings
          set fish_cursor_insert block
          ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

          if test -f ~/documents/gh/k/abbr.fish
              source ~/documents/gh/k/abbr.fish
          end
        '';
        shellAliases = {
          la = "eza -lah";
          cat = "bat";
          choose = "choose -x";
        };
      };
    };

    home.packages = with pkgs; [
      fishPlugins.autopair
      fishPlugins.colored-man-pages
      fishPlugins.done
      fishPlugins.grc
      fishPlugins.puffer
      fishPlugins.fzf-fish
    ];
  };
}
