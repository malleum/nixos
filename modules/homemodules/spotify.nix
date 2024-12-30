{osConfig, ...}: {
  services.spotifyd = {
    enable = true;
    settings.global = {
      username = "malleustempus@gmail.com";
      password_cmd = "~/OneDrive/Documents/Stuff/ProgrammingOrCodes/psswd/spotify.sh";
      device_name = "${osConfig.networking.hostName}";
      zeroconf_port = 1337;
    };
  };
  programs.spotify-player = {
    enable = true;
  };
}
