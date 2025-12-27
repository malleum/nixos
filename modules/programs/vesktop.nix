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
      };
      vencord.settings = {
        autoUpdate = true;
        useQuickCss = true;
        winCtrlQ = false;
        plugins = {
          FakeNitro.enabled = true;
          OpenInApp.enabled = true;
          ShowHiddenChannels.enabled = true;
          VoiceMessages.enabled = true;
          WhoReacted.enabled = true;
          ImageZoom.enabled = true;
          MessageClickActions.enabled = true;
          QuickReply.enabled = true;
          ShowMeYourName.enabled = true;
          SilentTyping.enabled = true;
          TypingIndicator.enabled = true;
          YoutubeAdblock.enabled = true;
        };
      };
    };
  };
}
