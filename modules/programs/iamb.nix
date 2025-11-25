{
  unify.modules.gui.home = {pkgs, ...}: {
    home = {
      packages = with pkgs; [iamb];
      file.".config/iamb/config.toml".source = (pkgs.formats.toml {}).generate "iamb-config" {
        profiles.user.user_id = "@malleum:malleum.us";
        layout.style = "restore";
        settings = {
          notifications.enabled = true;
          image_preview.protocol.type = "sixel";
        };
      };
    };
  };
}
