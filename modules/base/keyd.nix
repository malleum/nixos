{
  config,
  pkgs,
  ...
}: {
  environment.etc."keyd/default.conf".text = ''
    [ids]
    *

    [global]
    default_layout = dvorak

    [main]
    capslock = esc

    [dvorak:layout]

    ' = -
    , = w
    - = [
    . = v
    / = z
    1 = 1
    2 = 2
    3 = 3
    4 = 4
    5 = 5
    6 = 6
    7 = 7
    8 = 8
    9 = 9
    ; = s
    = = ]
    [ = /
    \ = \
    ] = =
    a = a
    b = x
    c = j
    d = e
    e = .
    f = u
    g = i
    h = d
    i = c
    j = h
    k = t
    l = n
    m = m
    n = b
    o = r
    p = l
    q = '
    r = p
    s = o
    t = y
    u = g
    v = k
    w = ,
    x = q
    y = f
    z = ;
    shift = layer(dvorak_shift)

    [dvorak_shift:S]
    ' = _
    , = W
    - = {
    . = V
    / = Z
    1 = !
    2 = @
    3 = #
    4 = $
    5 = %
    6 = ^
    7 = &
    8 = *
    9 = (
    ; = S
    = = }
    [ = ?
    \ = |
    ] = +
    a = A
    b = X
    c = J
    d = E
    e = >
    f = U
    g = I
    h = D
    i = C
    j = H
    k = T
    l = N
    m = M
    n = B
    o = R
    p = L
    q = "
    r = P
    s = O
    t = Y
    u = G
    v = K
    w = <
    x = Q
    y = F
    z = :
    scrolllock = setlayout(mcsr)


    [mcsr:layout]

    capslock = backspace

    leftcontrol = rightshift

    leftalt = i

    meta = alt

    tab = t
    ` = tab
    1 = 1
    2 = 2
    3 = 3
    4 = 4
    5 = 0
    6 = 5
    7 = 7
    8 = 8
    9 = 9
    0 = 6
    - = [
    = = ]

    q = e
    w = r
    e = n
    r = p
    t = y
    y = f
    u = g
    i = c
    o = r
    p = l
    [ = /
    ] = =
    \ = \

    a = b
    s = u
    d = s
    f = f
    g = g
    h = d
    j = h
    k = t
    l = n
    ; = s
    ' = -

    z = h
    x = l
    c = a
    v = k
    b = b
    n = x
    m = m
    , = w
    . = v
    / = z
    scrolllock = setlayout(dvorak)

  '';

  home-manager.users.joshammer.xdg.configFile."keyd/app.conf".text = ''
  '';

  systemd = {
    services.keyd-manual = {
      description = "keyd remapping daemon";
      wantedBy = ["multi-user.target"];
      after = ["local-fs.target"];

      restartTriggers = [
        config.environment.etc."keyd/default.conf".source
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.keyd}/bin/keyd";
        Restart = "always";
        RestartSec = 37;
        User = "root";
        NoNewPrivileges = false;
        ProtectSystem = false;
        ProtectHome = false;
      };
    };
  };

  home-manager.users.joshammer = {
    systemd.user.services = {
      keyd-application-mapper = {
        Unit = {
          Description = "keyd application mapper";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };

        Service = {
          ExecStart = ''${pkgs.fish}/bin/fish -c 'DISPLAY="" ${pkgs.keyd}/bin/keyd-application-mapper' '';
          Restart = "always";
          RestartSec = 1;
          RestartTriggers = [
            config.home-manager.users.joshammer.xdg.configFile."keyd/app.conf".source
          ];
        };
      };
    };

    # Conditionally create ~/.XCompose symlink
    home.file.".XCompose" = let
      keydCompose = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/rvaiya/keyd/master/data/keyd.compose";
        sha256 = "sha256-Oyob27hiS4KxRa8fimllANs9uHG0hTfrWk70c5G9Myc=";
      };
    in {
      source = keydCompose;
      # Only create the symlink if ~/.XCompose doesn't exist
      onChange = ''
        if [ -e "$HOME/.XCompose" ]; then
          echo "Skipping symlink creation: ~/.XCompose already exists"
        else
          ln -sf ${keydCompose} $HOME/.XCompose
        fi
      '';
    };
  };
  users.groups.keyd = {};
}
