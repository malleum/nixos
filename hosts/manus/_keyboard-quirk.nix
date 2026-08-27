{
  # Workarounds for ThinkPad AMD hardware bugs where the i8042 PS/2 controller
  # locks up under load or when holding a key, resulting in the keyboard freezing
  # and spamming a single key (e.g. 'j') during shutdown.
  boot.kernelParams = [
    "i8042.nomux=1"
    "i8042.reset"
    "i8042.nopnp=1"
    "i8042.dumbkbd=1"
  ];
}
