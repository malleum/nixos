{
  unify.modules.gui.nixos = {pkgs, ...}: {
    console.useXkbConfig = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "dvorak";
      options = "caps:escape";
    };

    environment.variables.XLOCALEDIR = "${pkgs.libx11}/share/X11/locale";
  };

  unify.modules.gui.home = {
    home.file.".XCompose".text = ''
      include "%L"

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

      <Multi_key> <o> <slash> : "ø"
      <Multi_key> <slash> <o> : "ø"
      <Multi_key> <O> <slash> : "Ø"
      <Multi_key> <slash> <O> : "Ø"
      <Multi_key> <a> <e> : "æ"
      <Multi_key> <A> <E> : "Æ"
      <Multi_key> <a> <a> : "å"
      <Multi_key> <A> <A> : "Å"
    '';
  };
}
