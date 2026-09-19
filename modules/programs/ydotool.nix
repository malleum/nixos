# ydotool: uinput-level input injection, for the waywall perch keybind
# (modules/programs/waywall.nix).
#
# wtype is the obvious alternative and does not work here. It needs
# virtual-keyboard-unstable-v1, which jay does not implement -- and neither does
# waywall, so running it inside waywall does not rescue it either. ydotool
# sidesteps the protocol question entirely by writing to /dev/uinput: the events
# enter as a kernel input device, so the host compositor routes them to whatever
# is focused and waywall forwards them to Minecraft like any real key.
{
  unify.modules.gam.nixos = {hostConfig, ...}: {
    programs.ydotool.enable = true;

    # The daemon's socket is group-owned (0660), so membership is what makes
    # `ydotool` usable without root.
    users.users.${hostConfig.user.username}.extraGroups = ["ydotool"];
  };
}
