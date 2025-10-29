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
        aring = "Aring";
        oslash = "Oslash";
      };
    in
      if specialCases ? ${str}
      then specialCases.${str}
      else lib.strings.toUpper str;
    footer = "\n\t};";
    keys = {
      "'" = "AD01";
      "," = "AD02";
      "." = "AD03";
      "p" = "AD04";
      "y" = "AD05";
      "f" = "AD06";
      "g" = "AD07";
      "c" = "AD08";
      "r" = "AD09";
      "l" = "AD10";
      "/" = "AD11";
      "=" = "AD12";
      "\\" = "AD13";
      "a" = "AC01";
      "o" = "AC02";
      "e" = "AC03";
      "u" = "AC04";
      "i" = "AC05";
      "d" = "AC06";
      "h" = "AC07";
      "t" = "AC08";
      "n" = "AC09";
      "s" = "AC10";
      "-" = "AC11";
      ";" = "AB01";
      "q" = "AB02";
      "j" = "AB03";
      "k" = "AB04";
      "x" = "AB05";
      "b" = "AB06";
      "m" = "AB07";
      "w" = "AB08";
      "v" = "AB09";
      "z" = "AB10";
      "lalt" = "LALT";
    };
    key = f: l: "\nkey <${keys.${f}}> { [ ${l}, ${capitalize l} ] };";
    layout = {
      # nreuf
      # øtZhw
      # salib
      "'" = "n";
      "," = "r";
      "." = "e";
      "p" = "u";
      "y" = "f";

      "a" = "oslash";
      "o" = "t";
      "e" = "d"; # will be replaced with Backspace
      "u" = "h";
      "i" = "w";

      ";" = "s";
      "q" = "a";
      "j" = "l";
      "k" = "i";
      "x" = "b";

      "lalt" = "aring";
    };
    keyboard = lib.strings.concatLines [header (lib.strings.concatLines (lib.mapAttrsToList key layout)) footer];
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
