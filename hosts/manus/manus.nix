{inputs, ...}: {
  hosts.manus = {
    tags = [
      "ai"
      "amd"
      "cht"
      "dev"
      "doc"
      "efi"
      "gui"
      "hyp"
      "lap"
      "med"
      "off"
      "prt"
      "src"
      "vrt"
      "wif"
      "wrk"
    ];

    # ThinkPad P16s Gen 4 AMD (21QR001SUS, Ryzen AI 7 PRO 350). Pulls in
    # trackpoint support + the amd cpu/gpu and pc-laptop/ssd baselines.
    modules = [
      ./_hardware-configuration.nix
      ./_keyboard-quirk.nix
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p16s-amd-gen4
    ];
  };
}
