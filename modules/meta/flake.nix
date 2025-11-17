{ inputs, ... }:
{
  imports = [ inputs.unify.flakeModule ];

  debug = false;

  # TODO: Should be a merge from the values set on hosts
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
}
