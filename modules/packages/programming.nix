{
  unify.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      alejandra
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
      nodejs
      pwntools
      python3
      rustc
      typst
      zig
    ];
  };
}
