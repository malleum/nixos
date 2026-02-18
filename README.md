# TODO
- [x] Dendritic with unify
- [ ] secrets
    - [x] age personal key
    - [x] oracle key
    - [x] github token
    - [x] vs key
    - [ ] gpg keys
    - [ ] gitlab key
- [x] outputs
    - [x] nixvim
    - [x] scripts
- [x] config for oracle
- [x] firefox
- [x] new nixvim
- [ ] switch wallpaper
- [ ] debug spotify_player

```nix
``.
├── flake.lock
├── flake.nix
├── hosts
│   ├── magnus
│   │   ├── _hardware-configuration.nix
│   │   └── magnus.nix
│   ├── malleum
│   │   ├── _hardware-configuration.nix
│   │   └── malleum.nix
│   ├── manus
│   │   ├── _hardware-configuration.nix
│   │   └── manus.nix
│   └── minimus
│       ├── _hardware-configuration.nix
│       ├── _network.nix
│       ├── _server.nix
│       └── minimus.nix
├── modules
│   ├── hardware
│   │   ├── amd.nix
│   │   ├── battery.nix
│   │   ├── bluetooth.nix
│   │   ├── keyboard.nix
│   │   ├── mcsr_keyboard.nix
│   │   ├── printer.nix
│   │   ├── screen_light.nix
│   │   └── wifi_mediatek.nix
│   ├── meta
│   │   ├── documentation.nix
│   │   ├── flake.nix
│   │   ├── flakepath.nix
│   │   ├── home.nix
│   │   ├── hostname.nix
│   │   ├── minimus-system.nix
│   │   ├── nix.nix
│   │   ├── nixpkgs.nix
│   │   ├── nvim.nix
│   │   ├── stateversion.nix
│   │   ├── user.nix
│   │   └── userConfig.nix
│   ├── packages
│   │   ├── ai.nix
│   │   ├── cli.nix
│   │   ├── coreutils.nix
│   │   ├── fonts.nix
│   │   ├── game.nix
│   │   ├── gui.nix
│   │   ├── iogii.nix
│   │   ├── programming.nix
│   │   ├── scripts.nix
│   │   └── wayland.nix
│   ├── programs
│   │   ├── brave.nix
│   │   ├── cli.nix
│   │   ├── firefox.nix
│   │   ├── fish.nix
│   │   ├── game.nix
│   │   ├── git.nix
│   │   ├── hypr.nix
│   │   ├── iamb.nix
│   │   ├── nh.nix
│   │   ├── nixhelpers.nix
│   │   ├── obs.nix
│   │   ├── rofi.nix
│   │   ├── spotify_player.nix
│   │   ├── starship.nix
│   │   ├── term.nix
│   │   ├── tmux.nix
│   │   ├── vesktop.nix
│   │   ├── virt.nix
│   │   ├── waybar.nix
│   │   ├── work.nix
│   │   └── zellij.nix
│   ├── scripts
│   │   ├── _chron.nix
│   │   ├── _cin.nix
│   │   ├── _disfiles.nix
│   │   ├── _duod.nix
│   │   ├── _ktv.nix
│   │   ├── _pyenv.nix
│   │   └── _themeswitcher.nix
│   ├── secrets
│   │   ├── default.yaml
│   │   ├── gpg.nix
│   │   ├── matrix.yaml
│   │   ├── oracle-ssh.yaml
│   │   └── sops.nix
│   ├── services
│   │   ├── clipboard.nix
│   │   ├── dunst.nix
│   │   ├── login_manager.nix
│   │   ├── matrix.nix
│   │   ├── ssd.nix
│   │   └── ssh.nix
│   ├── style
│   │   ├── _themes.nix
│   │   ├── stylix.nix
│   │   └── wallpapers
│   │       ├── grid.jpeg
│   │       ├── legotesla.png
│   │       ├── legotrain.png
│   │       ├── skyline.png
│   │       ├── space.png
│   │       ├── tall_dark_sky_su57.jpg
│   │       └── ws42.png
│   └── system
│       ├── audio.nix
│       ├── bios.nix
│       ├── docker.nix
│       ├── efi.nix
│       ├── locale.nix
│       ├── network.nix
│       ├── security.nix
│       ├── virtualization.nix
│       └── xdg.nix
├── nixvim
│   └── default.nix
└── README.md
`
