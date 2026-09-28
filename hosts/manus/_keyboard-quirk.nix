{
  # Workarounds for ThinkPad AMD hardware bugs where the i8042 PS/2 controller
  # locks up under load or when holding a key, resulting in the keyboard freezing
  # and spamming a single key (e.g. 'j') during shutdown.
  #
  # No i8042.dumbkbd: it did not prevent the lockup (recurred 2026-09-28), and
  # it stops atkbd from sending the keyboard any command at all -- no reset, no
  # LEDs -- so a wedged keyboard could never be reinitialised from the kernel.
  boot.kernelParams = [
    "i8042.nomux=1"
    "i8042.reset"
    "i8042.nopnp=1"
  ];
}
