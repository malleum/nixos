{
  unify.modules.med.home = {pkgs, ...}: let
    # home-manager does `cfg.package.override { withSystemVencord = ... }`,
    # so the wrap has to survive `.override` (symlinkJoin would drop it).
    wrapVesktop = vesktop:
      vesktop.overrideAttrs (old: {
        postFixup =
          (old.postFixup or "")
          + ''
            wrapProgram $out/bin/vesktop --add-flags "--password-store=gnome-libsecret"
          '';
      });
  in {
    programs.vesktop = {
      enable = true;
      # Jay is not GNOME; Electron will not auto-pick libsecret.
      package =
        (wrapVesktop pkgs.vesktop)
        // {
          override = args: wrapVesktop (pkgs.vesktop.override args);
        };
      settings = {
        discordBranch = "stable";
        transparencyOption = "blur";
        tray = true;
        minimizeToTray = true;
        hardwareAcceleration = true;
        autoStartMinimized = true;
        spellCheckLanguages = ["en-US"];
        splashTheming = true;
      };
      vencord.settings = {
        autoUpdate = true;
        useQuickCss = true;
        winCtrlQ = false;
        plugins = {
          AlwaysAnimate.enable = true;
          FakeNitro.enabled = true;
          ImageZoom.enabled = true;
          MessageClickActions.enabled = true;
          OpenInApp.enabled = true;
          QuickReply.enabled = true;
          ShowHiddenChannels.enabled = true;
          ShowMeYourName.enabled = true;
          SilentTyping.enabled = true;
          TypingIndicator.enabled = true;
          VoiceMessages.enabled = true;
          WhoReacted.enabled = true;
          YoutubeAdblock.enabled = true;
        };
      };
    };
  };
}
