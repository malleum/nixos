{pkgs, ...}: {
  programs = {
    fish = {
      enable = true;
      shellInit = ''
        alias tideconfig "tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time=No --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Compact --icons='Few icons' --transient=No"

        function fish_command_not_found
            echo skill issue: $argv[1]
        end

        function pyenv --description 'start a nix-shell with the given python packages'
          for el in $argv
            set ppkgs $ppkgs "python3Packages.$el"
          end
          nix-shell -p $ppkgs
        end

        set -g fish_greeting ""

        fish_vi_key_bindings
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '';
    };
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      defaultKeymap = "viins";
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initExtra = ''
        pyenv() {
          ppkgs=()
          for el in "$@"; do
            ppkgs+=("python3Packages.$el")
          done
          nix-shell -p "''${ppkgs[@]}"
        }

        ${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin
      '';
    };
    zoxide.enable = true;
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {};
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
    fishPlugins.tide

    eza
    fzf
    grc
  ];
}
