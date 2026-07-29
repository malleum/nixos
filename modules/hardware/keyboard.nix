# Console and X/Wayland keymap. Scoped to `gui`: minimus has no keyboard, and
# this was giving it a dvorak console and an services.xserver.xkb block.
{
  unify.modules.gui.nixos = {
    console.useXkbConfig = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "dvorak";
      options = "caps:escape";
    };
  };
}
