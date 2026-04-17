{
  unify.nixos = {
    console.useXkbConfig = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "dvorak";
      options = "caps:escape";
    };
  };
}
