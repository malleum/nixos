{
  unify.modules.gui.home = {config, ...}: {
    programs.spotify-player = {
      enable = true;
      settings = {
        client_id_command = {
          command = "cat";
          args = ["${config.homeDirectory}/documents/gh/k/spotify_id"];
        };
      };
    };
  };
}
