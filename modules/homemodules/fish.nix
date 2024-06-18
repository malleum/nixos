{pkgs, ...}: {
  programs = {
    fish = {
      enable = true;
      shellInit = ''
        alias tideconfig "tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time=No --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Compact --icons='Few icons' --transient=No"

        function fish_command_not_found
            echo skill issue: $argv[1]
        end

        function pythonEnv --description 'start a nix-shell with the given python packages' --argument pythonVersion
            if set -q argv[2]
              set argv $argv[2..-1]
            end
            for el in $argv
              set ppkgs $ppkgs "python"$pythonVersion"Packages.$el"
            end
            nix-shell -p $ppkgs
        end

        set -g fish_greeting ""

        fish_vi_key_bindings
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '';
    };
    zoxide.enable = true;
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
