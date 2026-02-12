{
  unify.modules.lap.nixos = {pkgs, ...}: {
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
      hplip # HP printers
      brlaser # Brother laser printers
      canon-cups-ufr2 # Canon printers
    ];
  };
}
