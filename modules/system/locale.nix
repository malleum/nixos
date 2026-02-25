{
  unify.nixos = {
    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";

    environment.etc."libinput/local-overrides.quirks".text = ''
      [Never Debounce]
      MatchUdevType=mouse
      ModelBouncingKeys=1

      [Roccat Kone Pro Fix]
      MatchName=*Kone Pro*
      ModelBouncingKeys=1
    '';
  };
}
