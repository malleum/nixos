# ServerFeed: the server-side half of the Matrix bridge.
#
# It reports join, leave, death and advancement over a loopback HTTP API and
# answers "who is online, and which of them are actually at the keyboard".
# Nothing in it knows what Matrix is -- see modules/services/_mc-matrix-bot.py
# for the half that does, and modules/services/mc.nix for the wiring.
#
# Built with javac against pinned jars for the same reason KeepInvList is: one
# source file does not justify vendoring a Gradle dependency lock. The HTTP
# server is a JDK built-in (com.sun.net.httpserver), so the only compile
# dependencies are Paper's API and what Paper's API drags in.
{
  fetchurl,
  jdk25,
  runCommand,
}: let
  paperBuild = "26.3.build.34-alpha";

  paperApi = fetchurl {
    url = "https://repo.papermc.io/repository/maven-public/io/papermc/paper/paper-api/${paperBuild}/paper-api-${paperBuild}.jar";
    hash = "sha256-yqxMtPQGkiZmAOYHmfWF13/9QeSL2Pik+byyjy4pddo=";
  };

  # As in mc-keepinv: javac resolves the full signature of everything it
  # touches, so paper-api's own dependencies have to be on the classpath. The
  # extra one here is adventure's plain-text serializer -- death messages and
  # advancement titles arrive as Components and Matrix wants characters.
  deps = [
    (fetchurl {
      url = "https://repo1.maven.org/maven2/net/kyori/adventure-api/5.2.0/adventure-api-5.2.0.jar";
      hash = "sha256-flL+cZC+Poezs/cXEs+hIxX80nEJ8wKntEDBLwH66Cc=";
    })
    (fetchurl {
      url = "https://repo1.maven.org/maven2/net/kyori/adventure-key/5.2.0/adventure-key-5.2.0.jar";
      hash = "sha256-AYTRcyAOLu+PvHkfYi0dWP1Fn4kwxha1pP556D7abFU=";
    })
    (fetchurl {
      url = "https://repo1.maven.org/maven2/net/kyori/adventure-text-serializer-plain/5.2.0/adventure-text-serializer-plain-5.2.0.jar";
      hash = "sha256-9kJMwDimMbecxLdLazU9XQB8mbOPm+SC4MJEigDuzSE=";
    })
    (fetchurl {
      url = "https://repo1.maven.org/maven2/com/google/guava/guava/33.4.8-jre/guava-33.4.8-jre.jar";
      hash = "sha256-89f1f2f9Yi9NRo391pKzpeOQkkbCgBesMmNAXw/mF+0=";
    })
    (fetchurl {
      url = "https://repo1.maven.org/maven2/org/jetbrains/annotations/26.0.2/annotations-26.0.2.jar";
      hash = "sha256-IDe+N4mA07qTM+l5VfOyzeOSqhJNBMpzzi7uZlcZkpc=";
    })
    (fetchurl {
      url = "https://repo1.maven.org/maven2/org/jspecify/jspecify/1.0.0/jspecify-1.0.0.jar";
      hash = "sha256-H61ua+dVd4Hk0zcp1Jrhzcj92m/kd7sMxozjUer9+6s=";
    })
  ];

  classpath = builtins.concatStringsSep ":" ([paperApi] ++ deps);
in
  runCommand "ServerFeed.jar" {
    nativeBuildInputs = [jdk25];
    meta = {
      description = "Loopback event feed and online/AFK status for a Paper server";
      platforms = jdk25.meta.platforms;
    };
  } ''
    mkdir -p classes
    javac -cp ${classpath} -d classes ${./src}/com/joshammer/mcfeed/ServerFeed.java
    cp ${./src}/plugin.yml classes/plugin.yml
    jar --create --file $out -C classes .
  ''
