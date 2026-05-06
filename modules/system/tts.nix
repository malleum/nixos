{self, ...}: {
  perSystem = {pkgs, ...}: let
    piperVoiceOnnx = pkgs.fetchurl {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/no/no_NO/talesyntese/medium/no_NO-talesyntese-medium.onnx";
      sha256 = "04qc4wqxbig2b36vyxdr4gjzy1cg8j5lnk07qhl4cb770azawqxp";
      name = "no_NO-talesyntese-medium.onnx";
    };
    piperVoiceJson = pkgs.fetchurl {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/no/no_NO/talesyntese/medium/no_NO-talesyntese-medium.onnx.json";
      sha256 = "1m89365awygmdyrhcr1ifj9gav1vfzwarj7a5cyq9ycbzj8h9sxh";
      name = "no_NO-talesyntese-medium.onnx.json";
    };
    voiceDir = pkgs.runCommand "piper-voice-no-talesyntese" {} ''
      mkdir -p $out
      cp ${piperVoiceOnnx} $out/no_NO-talesyntese-medium.onnx
      cp ${piperVoiceJson} $out/no_NO-talesyntese-medium.onnx.json
    '';
    piperBin = "${pkgs.piper-tts}/bin/piper";
    aplayBin = "${pkgs.alsa-utils}/bin/aplay";
    voiceModel = "${voiceDir}/no_NO-talesyntese-medium.onnx";
    sayCmd = pkgs.writeShellScriptBin "say" ''
      length_scale=1.0
      add_commas=0
      while getopts "cs:" opt; do
        case "$opt" in
          c) add_commas=1 ;;
          s) length_scale="$OPTARG" ;;
        esac
      done
      shift $((OPTIND - 1))

      if [ $# -gt 0 ]; then
        input="$*"
      else
        input="$(cat)"
      fi

      if [ "$add_commas" -eq 1 ]; then
        input="$(printf '%s' "$input" | ${pkgs.gawk}/bin/awk '{for(i=1;i<=NF;i++){printf "%s%s", $i, (i<NF?", ":"")} print ""}')"
      fi

      printf '%s' "$input" | ${piperBin} -m ${voiceModel} --length-scale "$length_scale" --output-raw | ${aplayBin} -r 22050 -f S16_LE -c 1 -t raw -
    '';
  in {
    packages.say = sayCmd;
    packages.piper-voice-no-talesyntese = voiceDir;
    apps.say = {
      type = "app";
      program = "${sayCmd}/bin/say";
    };
  };

  unify.modules.gui.home = {pkgs, ...}: let
    system = pkgs.stdenv.hostPlatform.system;
    sayCmd = self.packages.${system}.say;
    voiceDir = self.packages.${system}.piper-voice-no-talesyntese;
    piperBin = "${pkgs.piper-tts}/bin/piper";
    aplayBin = "${pkgs.alsa-utils}/bin/aplay";
    sdGeneric = "${pkgs.speechd}/libexec/speech-dispatcher-modules/sd_generic";
    voiceModel = "${voiceDir}/no_NO-talesyntese-medium.onnx";
  in {
    xdg.configFile = {
      "speech-dispatcher/speechd.conf".text = ''
        LogLevel 3
        LogDir "default"
        DefaultLanguage "nb"
        AddModule "piper-generic" "${sdGeneric}" "piper-generic.conf"
        DefaultModule piper-generic
      '';
      "speech-dispatcher/modules/piper-generic.conf".text = ''
        GenericExecuteSynth \
        "printf %s \'$DATA\' | ${piperBin} -m ${voiceModel} --output-raw | ${aplayBin} -r 22050 -f S16_LE -c 1 -t raw -"

        GenericCmdDependency "piper"

        AddVoice "nb" "MALE1" "nb_NO-talesyntese"
        AddVoice "no" "MALE1" "nb_NO-talesyntese"

        DefaultVoice "nb_NO-talesyntese"
      '';
    };
    home.packages = with pkgs; [
      speechd
      piper-tts
      alsa-utils
      sayCmd
    ];
  };
}
