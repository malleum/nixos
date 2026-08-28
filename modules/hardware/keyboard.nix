# Console and X/Wayland keymap. Scoped to `gui`: minimus has no keyboard, and
# this was giving it a dvorak console and an services.xserver.xkb block.
{
  unify.modules.gui.nixos = {
    services.xserver.xkb = {
      layout = "us";
      variant = "dvorak";
      options = "caps:escape";
    };
  };

  unify.modules.gui.home = {
    home.file.".XCompose".text = ''
      include "%L"

      # Esperanto quick compose sequences
      <Multi_key> <c> : "ĉ"
      <Multi_key> <C> : "Ĉ"
      <Multi_key> <g> : "ĝ"
      <Multi_key> <G> : "Ĝ"
      <Multi_key> <h> : "ĥ"
      <Multi_key> <H> : "Ĥ"
      <Multi_key> <j> : "ĵ"
      <Multi_key> <J> : "Ĵ"
      <Multi_key> <s> : "ŝ"
      <Multi_key> <S> : "Ŝ"
      <Multi_key> <u> : "ŭ"
      <Multi_key> <U> : "Ŭ"
    '';
  };
}
