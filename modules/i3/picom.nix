{
  lib,
  config,
  ...
}: {
  options.picom.enable = lib.mkEnableOption "enables picom";

  config = lib.mkIf config.picom.enable {
    services.picom = {
      enable = true;
      fade = false;
      vSync = true;
      backend = "glx";
      #fadeDelta = 1;
      shadowExclude = ["_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"];
      opacityRules = ["70:class_g = 'URxvt' && !_NET_WM_STATE@:32a" "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"];
    };
  };
}
