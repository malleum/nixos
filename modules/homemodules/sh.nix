{
  pkgs,
  lib,
  ...
}: {
  programs = {
    fish = let
      themes = import ../stylix/themes.nix {inherit pkgs;};

      wallpaper-script = lib.concatMapStringsSep "\n" (name: ''
        case "${name}"; swww img "${themes.${name}.image}" --transition-type any --transition-fps 60
      '') (lib.attrNames themes);
    in {
      enable = true;
      shellInit = ''
        function fish_command_not_found
            echo skill issue: $argv[1]
        end

        function set_wallpaper
            switch $argv[1]
                ${wallpaper-script}
            end
        end

        function theme
            sudo "/nix/var/nix/profiles/system/specialisation/$argv[1]/bin/switch-to-configuration" switch & disown
            sleep 1
            set_wallpaper theme
        end

        set -g fish_greeting ""

        fish_vi_key_bindings
        set fish_cursor_insert block
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

        alias cat "bat";
        alias la "ls -lah";
        alias ls "eza --icons --color";
        alias nixvim "nix run ~/.config/nixos#default";
        alias rm "echo Use 'rip' instead of rm";

        abbr -a stag "STAGING_BRANCH=(git branch --show-current)"
        abbr -a prod 'VS_RUN_PROD=1'
        abbr -a rpy rg --iglob='\'*.py'\'

        if test -f ~/documents/gh/k/abbr.fish
            source ~/documents/gh/k/abbr.fish
        end
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
  home = {
    sessionVariables = {
      MANPAGER = "sh -c 'col -bx | ${pkgs.grc}/bin/grc --colour -s | ${pkgs.less}/bin/less -R'";
    };
    packages = with pkgs; [
      fishPlugins.autopair
      fishPlugins.colored-man-pages
      fishPlugins.done
      fishPlugins.grc
      fishPlugins.puffer

      eza
      fzf
      grc
    ];
  };
}
