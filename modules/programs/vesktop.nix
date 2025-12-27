{
  unify.modules.gui.home = {
    programs.vesktop = {
      enable = true;
      settings = {
        discordBranch = "stable";
        transparencyOption = "blur";
        tray = true;
        minimizeToTray = true;
        hardwareAcceleration = true;
        autoStartMinimized = true;
        spellCheckLanguages = ["en-US"];
        splashBackground = "../style/wallpapers/gojo.mp4";
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
