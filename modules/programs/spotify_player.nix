{
  unify.modules.gui.home =
    { config, ... }:
    {
      programs.spotify-player = {
        enable = true;
        settings = {
          client_id_command = {
            command = "cat";
            args = [ config.sops.secrets.spotify_client_id.path ];
          };
        };
      };
    };
}
