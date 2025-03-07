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
        set fish_cursor_insert block
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '';
    };
    zoxide.enable = true;
    starship = {
      enable = true;
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
