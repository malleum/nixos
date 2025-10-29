{
  unify.nixos = {pkgs, ...}: {
    programs.fish.enable = true;
    environment = {
      shells = [pkgs.fish];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        BROWSER = "brave";
        TERMINAL = "foot";
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
