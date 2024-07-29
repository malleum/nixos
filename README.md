# okay 🆗

## Normal way
- `sudo nixos rebuild switch --flake`

## Cool way (with nix helper (nh))
- `nh os switch`

## normal way to update inputs in the flake so you can update packages
- `nix flake update`

## cool way
- `nh os switch -u`  # updates flake, and then rebuilds system

## removed unused packages
- `nix-collect-garbage -d`
- `nh clean all` (cool way, and actually cleans more things)

## install packages imperatively (almost always a bad idea)
- `nix profile install nixpkgs#gh` # this is the only way I can reccomend using it (idk why `gh` doesn't work when in systemPackages = [];), 
    - otherwise use `nix run` or a nix shell or just put in the packages list, depending on whether you need it once, a couple times, or a lot
    - because if you use `nix run` or a nix shell, it will get cleaned once you do a nix clean (a garbage collection), but with `nix profile` you have to remember it is there and update/remove it manually
- `nix profile install github:speedster/nixvim`
- `nix profile list`

## temporary shell with package(s) 
- `nix-shell -p sl` # old
- `nix shell nixpkgs#sl` # new (they have the same functionality, as far as I can tell)
- `nix shell github:speedster/nixvim` for a github flake

## shell with python dependancies
- `nix-shell -p python311Packages.numpy python311Packages.pandas` 
- `nix shell nixpkgs#python311Packages.numpy nixpkgs#python311Packages.pandas`
- probably want to add those to a shell.nix shellhook instead if you need to repeatably do it

## a single run
- `nix run github:speedster/nixvim` # for a github flake
- `nix run nixpkgs#sl` # for a nixpkgs package
