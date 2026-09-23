{
  unify.nixos = {
    hostConfig,
    pkgs,
    ...
  }: {
    networking.networkmanager.enable = true;

    # Nothing was ever setting a country, so the cfg80211 core sits at the "00"
    # world domain, where most of 5 GHz is PASSIVE-SCAN and 6 GHz is absent.
    # hardware.wirelessRegulatoryDatabase is already true, so the db is present;
    # only the hint was missing.
    #
    # This does NOT affect magnus. ath12k registers a self-managed wiphy, which
    # takes its domain from firmware and ignores the core setting entirely --
    # `iw reg get` there shows "phy#0 (self-managed) country US: DFS-FCC" while
    # the global line still reads "country 00". It was already correct, and the
    # 5 GHz trouble documented in wifi_ath12k.nix was never regulatory.
    #
    # Kept for the hosts whose drivers are not self-managed (mt7925 and the
    # wpa_supplicant laptops), where the core domain is what they actually use.
    # Always check the per-phy stanza from `iw reg get`, not the global one.
    boot.extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom="US"
    '';

    # iw is the only way to read the per-phy regulatory domain and the real
    # negotiated PHY rate; diagnosing the above without it was needlessly hard.
    environment.systemPackages = [pkgs.iw];

    users.users.${hostConfig.user.username}.extraGroups = ["networkmanager"];
  };
}
