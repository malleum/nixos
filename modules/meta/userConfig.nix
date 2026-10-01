{lib, ...}: let
  inherit (lib) mkOption types;

  email = "jph33@outlook.com";
  name = "Josh Hammer";
  username = "joshammer";
  gitusername = "malleum";
  homeDirectory = "/home/${username}";
  configHome = "${homeDirectory}/.config";
  browser = "firefox";
  browser2 = "brave";
in {
  options.user = mkOption {
    type = types.attrsOf types.str;
    default = {
      inherit
        email
        name
        username
        homeDirectory
        configHome
        gitusername
        browser
        browser2
        ;
    };
  };
}
