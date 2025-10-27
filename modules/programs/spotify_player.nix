{
  unify.modules.gui.home = {hostConfig, ...}: {
    programs.spotify-player = {
      enable = true;
      settings = {
        client_id_command = {
          command = "cat";
          args = ["${hostConfig.homeDirectory}/documents/gh/k/spotify_id"];
        };
      };
    };
  };
}
