{inputs, ...}: {
  imports = [inputs.unify.flakeModule]; # TODO: what does this mean?

  debug = false;

  # TODO: Should be a merge from the values set on hosts
  systems = ["x86_64-linux"];
}
