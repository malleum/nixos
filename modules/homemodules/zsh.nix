{
  pkgs,
  lib,
  ...
}: {
  programs = {
    fish = {
      enable = true;
      shellInit = ''
        function fish_command_not_found
            echo skill issue: $argv[1]
        end

        set -g fish_greeting ""

        fish_vi_key_bindings
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '';
    };
    zsh = {
      enable = true;
      autocd = true;
      dotDir = ".config/zsh";
      defaultKeymap = "viins";
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initExtra = ''
        zstyle ':completion:*' matcher-list 'r:|?=**' 'm:{a-zA-Z}={A-Za-z}'
        autopair-init
        ${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin
      '';
      plugins = [
        {
          name = "zsh-replace-multiple-dots";
          file = "replace-multiple-dots.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "momo-lab";
            repo = "zsh-replace-multiple-dots";
            rev = "dd2a68b031fc86e2f10f34451e0d79cdb4981bfd";
            sha256 = "sha256-T4hDTYjnsPWXGhAM4Kf4z5KMyR12zJrM3vW8QM6JR0w=";
          };
        }
        {
          name = "zsh-autopair";
          file = "autopair.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "449a7c3d095bc8f3d78cf37b9549f8bb4c383f3d";
            sha256 = "sha256-3zvOgIi+q7+sTXrT+r/4v98qjeiEL4Wh64rxBYnwJvQ= ";
          };
        }
      ];
    };
    zoxide.enable = true;
    starship = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      settings = {
        add_newline = true;
        format = lib.concatStrings [
          "$directory"
          "$git_branch"
          "$git_commit"
          "$git_state"
          "$git_metrics"
          "$git_status"
          "$line_break"
          "$character"
        ];
        right_format = lib.concatStrings [
          "$cmd_duration"
          "$nix_shell"
          "$direnv"
          "$docker_context"
          "$c"
          "$cmake"
          "$dart"
          "$deno"
          "$dotnet"
          "$golang"
          "$java"
          "$julia"
          "$kotlin"
          "$gradle"
          "$lua"
          "$nodejs"
          "$python"
          "$rust"
          "$typst"
          "$zig"
          "$line_break"
        ];
        scan_timeout = 10;
        character = {
          error_symbol = "[✗](bold red)";
        };
        directory = {
          truncation_length = 13;
          truncate_to_repo = false;
        };
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
  home.packages = with pkgs; [
    fishPlugins.autopair
    fishPlugins.colored-man-pages
    fishPlugins.done
    fishPlugins.grc
    fishPlugins.puffer

    eza
    fzf
    grc
  ];
}
