{
  unify.home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        cargo
        clang-tools
        gcc
        gdb
        gnumake
        go
        gradle
        jdk21
        kotlin
        leiningen
        lua
        nixfmt-rfc-style
        nodejs
        pwntools
        python3
        rustc
        typst
        zig
      ];
    };
}
