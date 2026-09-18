{
  unify.modules.gam.nixos = {lib, ...}: let
    header = ''
      default partial alphanumeric_keys
      xkb_symbols "mcsr" {
          include "us"

          name[Group1]= "MCSR for Waywall";
    '';

    capitalize = str: let
      specialCases = {
        semicolon = "colon"; # ; -> :
        period = "greater"; # . -> >
        comma = "less"; # , -> <
        apostrophe = "quotedbl"; # ' -> "
        ccircumflex = "Ccircumflex";
        underscore = "underscore";
        BackSpace = "BackSpace";
        VoidSymbol = "VoidSymbol";
      };
    in
      if specialCases ? ${str}
      then specialCases.${str}
      else lib.strings.toUpper str;
    footer = "\n\t};";

    key = code: l: "\nkey <${code}> { [ ${l}, ${capitalize l} ] };";

    # Esperanto searchcrafting layout (see ~/documents/gh/mcsr/esperanto.md).
    # Keys are raw xkb codes, i.e. physical positions; the letter next to each
    # is the QWERTY legend of that position, not what the key now produces.
    #
    # This layer owns everything that arrives as *text* in the recipe-search
    # box. Game binds are not here: GLFW on Wayland keys off raw evdev
    # scancodes and never consults the layout, so those live in waywall's
    # remap table (modules/programs/waywall.nix).
    layout = {
      #        t o ĉ n
      #  i     a s ⌫ k
      #  0     _ h f r
      #                j
      # "i" sits on Dot, not Tab, because waywall remaps physical Tab -> Dot so
      # that Grave can be the real Tab. The key under the finger is still Tab.
      "AB09" = "i"; # . (reached by pressing Tab)
      "AD01" = "t"; # q
      "AD02" = "o"; # w
      "AD03" = "ccircumflex"; # e
      "AD04" = "n"; # r

      # CAPS -> 0 and AC03 -> Backspace are NOT here: Minecraft refuses the
      # keycodes this layer emits for those two and only accepts the ones
      # waywall's remap table produces, so both live there instead.
      "AC01" = "a"; # a
      "AC02" = "s"; # s
      "AC04" = "k"; # f

      "AB01" = "underscore"; # z
      "AB02" = "h"; # x
      "AB03" = "f"; # c
      "AB04" = "r"; # v

      "LALT" = "j";

      # MCSR rule A.10.1: one output may come from at most one key. "us" still
      # types these at their QWERTY spots, so blank every duplicate source.
      "AD05" = "VoidSymbol"; # t
      "AD06" = "VoidSymbol"; # f
      "AD08" = "VoidSymbol"; # i
      "AD09" = "VoidSymbol"; # o
      "AC06" = "VoidSymbol"; # h
      "AC07" = "VoidSymbol"; # j
      "AC08" = "VoidSymbol"; # k
      "AB06" = "VoidSymbol"; # n
      # AE10 (0) and BKSP stay live: they are the targets waywall remaps CAPS
      # and D onto. Their originals are parked on F23/F22 over there, so each
      # output still has exactly one source.
    };

    # Shift+minus is the other source of "_", so kill only that level and keep
    # the unshifted "-" usable.
    extraKeys = "\nkey <AE11> { [ minus, VoidSymbol ] };";

    keyboard = lib.strings.concatLines [
      header
      (lib.strings.concatLines (lib.mapAttrsToList key layout))
      extraKeys
      footer
    ];
  in {
    services.xserver.xkb.extraLayouts = {
      mcsr = {
        description = "MCSR Custom Layout";
        languages = ["eng"];
        symbolsFile = builtins.toFile "mcsrkeyboard.xkb" keyboard;
      };
    };
  };
}
