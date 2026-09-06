{
  unify.modules.prt.nixos = {pkgs, ...}: {
    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable Avahi for network printer discovery (.local addresses)
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Optional: Common drivers (uncomment or add what you need)
    services.printing.drivers = with pkgs; [
      gutenprint # Generic drivers for many printers
      # withQt5 = false: PyQt5 5.15.10 does not support Python 3.14 (sip
      # "ABI v12 is being targeted but the PyQt5.QtCore module doesn't support
      # it"), and nixpkgs-unstable now defaults to 3.14, so the stock hplip
      # fails to build. Qt5 only buys the hp-toolbox / hp-setup GUIs; the CUPS
      # backends and PPDs -- the only part services.printing.drivers uses --
      # are unaffected.
      (hplip.override {withQt5 = false;}) # HP printers
      brlaser # Brother laser printers
      canon-cups-ufr2 # Canon printers
    ];
  };
}
