let
  # The 12 SDN positive and negative prefixes
  prefixes = [
    {
      name = "";
      uni = "";
      asc = "";
      rel = "1";
    }

    {
      name = "unqua";
      uni = "u↑";
      asc = "uq";
      rel = "12";
    }
    {
      name = "biqua";
      uni = "b↑";
      asc = "bq";
      rel = "12^2";
    }
    {
      name = "triqua";
      uni = "t↑";
      asc = "tq";
      rel = "12^3";
    }
    {
      name = "quadqua";
      uni = "q↑";
      asc = "qq";
      rel = "12^4";
    }
    {
      name = "pentqua";
      uni = "p↑";
      asc = "pq";
      rel = "12^5";
    }
    {
      name = "hexqua";
      uni = "h↑";
      asc = "hq";
      rel = "12^6";
    }

    {
      name = "uncia";
      uni = "u↓";
      asc = "uc";
      rel = "1/12";
    }
    {
      name = "bicia";
      uni = "b↓";
      asc = "bc";
      rel = "1/(12^2)";
    }
    {
      name = "tricia";
      uni = "t↓";
      asc = "tc";
      rel = "1/(12^3)";
    }
    {
      name = "quadcia";
      uni = "q↓";
      asc = "qc";
      rel = "1/(12^4)";
    }
    {
      name = "pentcia";
      uni = "p↓";
      asc = "pc";
      rel = "1/(12^5)";
    }
    {
      name = "hexcia";
      uni = "h↓";
      asc = "hc";
      rel = "1/(12^6)";
    }
  ];

  # The core Primel units and their mathematical SI definitions
  baseUnits = [
    {
      name = "timel";
      abbr = "tml";
      unit = "d";
      rel = "1/(12^6)";
    }
    {
      name = "lengthel";
      abbr = "lgl";
      unit = "m";
      rel = "9.80665 * (86400 / 12^6)^2";
    }
    {
      name = "massel";
      abbr = "msl";
      unit = "kg";
      rel = "1000 * (9.80665 * (86400 / 12^6)^2)^3";
    }
    {
      name = "velocel";
      abbr = "vlcl";
      unit = "m_p_s";
      rel = "9.80665 * (86400 / 12^6)";
    }
    {
      name = "accel";
      abbr = "accl";
      unit = "m_p_sqs";
      rel = "9.80665";
    }
    {
      name = "areal";
      abbr = "arl";
      unit = "sqm";
      rel = "(9.80665 * (86400 / 12^6)^2)^2";
    }
    {
      name = "volumel";
      abbr = "vlml";
      unit = "cum";
      rel = "(9.80665 * (86400 / 12^6)^2)^3";
    }
    {
      name = "forcel";
      abbr = "frcl";
      unit = "N";
      rel = "(1000 * (9.80665 * (86400 / 12^6)^2)^3) * 9.80665";
    }
    {
      name = "pressel";
      abbr = "prsl";
      unit = "Pa";
      rel = "((1000 * (9.80665 * (86400 / 12^6)^2)^3) * 9.80665) / ((9.80665 * (86400 / 12^6)^2)^2)";
    }
    {
      name = "energel";
      abbr = "engl";
      unit = "J";
      rel = "((1000 * (9.80665 * (86400 / 12^6)^2)^3) * 9.80665) * (9.80665 * (86400 / 12^6)^2)";
    }
    {
      name = "powrel";
      abbr = "pwrl";
      unit = "W";
      rel = "(((1000 * (9.80665 * (86400 / 12^6)^2)^3) * 9.80665) * (9.80665 * (86400 / 12^6)^2)) / (86400 / 12^6)";
    }
    {
      name = "densel";
      abbr = "dnsl";
      unit = "kg_p_cum";
      rel = "1000";
    }
  ];

  # Colloquial names for specific powers of timel
  colloquialTime = {
    "" = {
      name = "vibe";
      abbr = "vb";
    };
    "unqua" = {
      name = "twinkling";
      abbr = "tw";
    };
    "biqua" = {
      name = "lull";
      abbr = "lu";
    };
    "triqua" = {
      name = "trice";
      abbr = "tr";
    };
    "quadqua" = {
      name = "breather";
      abbr = "br";
    };
    "pentqua" = {
      name = "dwell";
      abbr = "dw";
    };
    "hexqua" = {
      name = "day";
      abbr = "dy";
    };
  };

  # Helper to capitalize first letter
  capitalize = str: let
    firstChar = builtins.substring 0 1 str;
    rest = builtins.substring 1 (builtins.stringLength str - 1) str;
    upperFirst =
      {
        "a" = "A";
        "b" = "B";
        "c" = "C";
        "d" = "D";
        "e" = "E";
        "f" = "F";
        "g" = "G";
        "h" = "H";
        "i" = "I";
        "j" = "J";
        "k" = "K";
        "l" = "L";
        "m" = "M";
        "n" = "N";
        "o" = "O";
        "p" = "P";
        "q" = "Q";
        "r" = "R";
        "s" = "S";
        "t" = "T";
        "u" = "U";
        "v" = "V";
        "w" = "W";
        "x" = "X";
        "y" = "Y";
        "z" = "Z";
      }.${
        firstChar
      } or firstChar;
  in
    upperFirst + rest;

  # Generate XML for a single permutation of (baseUnit, prefix)
  generateUnit = {
    b,
    p,
  }: let
    fullName = p.name + b.name;
    title = capitalize fullName;

    names =
      if p.name == ""
      then
        [
          "ar:${b.abbr}"
          "ar:⚀${b.abbr}"
          fullName
          "p:${fullName}s"
        ]
        ++ (
          if b.name == "timel"
          then [
            "ar:${colloquialTime.${p.name}.abbr}"
            colloquialTime.${p.name}.name
            "p:${colloquialTime.${p.name}.name}s"
          ]
          else []
        )
      else
        [
          "ar:${p.uni}${b.abbr}"
          "ar:⚀${p.uni}${b.abbr}"
          "ar:${p.asc}${b.abbr}"
          fullName
          "p:${fullName}s"
        ]
        ++ (
          if b.name == "timel" && builtins.hasAttr p.name colloquialTime
          then [
            "ar:${colloquialTime.${p.name}.abbr}"
            colloquialTime.${p.name}.name
            "p:${colloquialTime.${p.name}.name}s"
          ]
          else []
        );

    namesStr = builtins.concatStringsSep "," names;
    relationStr =
      if p.rel == "1"
      then b.rel
      else "(${b.rel}) * (${p.rel})";
  in ''
    <unit type="alias">
      <title>${title}</title>
      <names>${namesStr}</names>
      <base>
        <unit>${b.unit}</unit>
        <relation>${relationStr}</relation>
        <exponent>1</exponent>
      </base>
    </unit>'';

  # Generate all Primel units
  primelUnitsXML = builtins.concatStringsSep "\n" (
    builtins.concatMap (
      b:
        map (p: generateUnit {inherit b p;}) prefixes
    )
    baseUnits
  );
in ''
  <?xml version="1.0" encoding="UTF-8"?>
  <QALCULATE version="5.12.0">
    <category>
      <title>Primel Units</title>
  ${primelUnitsXML}
    </category>
    <category>
      <title>Custom Units</title>
      <unit type="alias">
        <title>Chron</title>
        <names>ar:ch,chron,p:chrons</names>
        <base>
          <unit>s</unit>
          <relation>864</relation>
          <exponent>1</exponent>
        </base>
        <use_with_prefixes>true</use_with_prefixes>
      </unit>
      <unit type="alias">
        <title>Duod</title>
        <names>ar:duod,duod,p:duods</names>
        <base>
          <unit>s</unit>
          <relation>86400</relation>
          <exponent>1</exponent>
        </base>
      </unit>
    </category>
  </QALCULATE>
''
