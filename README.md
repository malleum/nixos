# TODO
- [x] Dendritic with unify
- [ ] secrets
    - [ ] age personal key
    - [ ] ssh keys x3
    - [ ] github token
    - [ ] gpg keys
    - [ ] gitlab key
- [ ] outputs
    - [ ] nixvim
    - [ ] scripts
- [ ] hm config for oracle
- [ ] firefox
- [ ] nvf
- [ ] switch wallpaper

```nix
.
├── flake.lock
├── flake.nix
├── hosts
│   ├── magnus
│   │   ├── _hardware-configuration.nix
│   │   └── magnus.nix
│   └── malleum
│       ├── _hardware-configuration.nix
│       └── malleum.nix
├── modules
│   ├── hardware
│   │   ├── amd.nix
│   │   ├── battery.nix
│   │   ├── bluetooth.nix
│   │   ├── keyboard.nix
│   │   ├── mcsr_keyboard.nix
│   │   └── screen_light.nix
│   ├── meta
│   │   ├── flake.nix
│   │   ├── flakepath.nix
│   │   ├── home.nix
│   │   ├── hostname.nix
│   │   ├── nix.nix
│   │   ├── nixpkgs.nix
│   │   ├── stateversion.nix
│   │   ├── user.nix
│   │   └── userConfig.nix
│   ├── nixvim
│   │   ├── _lsp.nix
│   │   ├── _options.nix
│   │   ├── _plugins.nix
│   │   ├── _zoom.nix
│   │   └── default.nix
│   ├── packages
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
│   │   ├── fish.nix
│   │   ├── game.nix
│   │   ├── git.nix
│   │   ├── hypr.nix
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
│   │   └── work.nix
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
│   │   └── sops.nix
│   ├── services
│   │   ├── clipboard.nix
│   │   ├── dunst.nix
│   │   ├── login_manager.nix
│   │   ├── ssd.nix
│   │   └── ssh.nix
│   ├── style
│   │   ├── _themes.nix
│   │   ├── stylix.nix
│   │   └── wallpapers
│   │       ├── grid.jpeg
│   │       ├── legotesla.png
│   │       ├── skyline.png
│   │       ├── space.png
│   │       └── tall_dark_sky_su57.jpg
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
├── README.md
└── vimium_c.json
```
