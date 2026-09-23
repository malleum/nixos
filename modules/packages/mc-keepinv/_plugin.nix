# KeepInvList: the one gameplay plugin on the server, and it exists only
# because the thing it does is impossible without code.
#
# keepInventory is a world gamerule, a single boolean for everyone on the
# server. "These five players keep their stuff, everyone else drops it like
# vanilla" therefore cannot be expressed as configuration, by a datapack, or by
# any arrangement of vanilla features. The alternatives were a third-party
# plugin driven by a permissions plugin (two dependencies, one of which -- the
# permission manager -- hands players commands), or sixty lines of Java. This
# is the sixty lines.
#
# It is compiled by hand rather than with Gradle, because a Gradle build in Nix
# means vendoring a dependency lock for a project with one source file. javac
# against pinned jars is the whole build.
#
# Paper's API jar is published per build, so the compile classpath is the exact
# server this runs on -- see modules/services/mc.nix for the matching server
# jar. Paper 26.3 is Java 25 (class file version 69), hence jdk25.
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

  # javac resolves the whole signature of everything it touches, so the API's
  # own dependencies have to be on the classpath even though this plugin names
  # none of them: Player implements adventure's Audience, ItemMeta returns a
  # Guava Multimap, the API is annotated with JetBrains' and JSpecify's
  # nullability annotations. Versions come from paper-api's pom
  # (adventure-bom 5.2.0, guava 33.4.8-jre).
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
  runCommand "KeepInvList.jar" {
    nativeBuildInputs = [jdk25];
    meta = {
      description = "Per-player keep-inventory for a Paper server, list-driven";
      platforms = jdk25.meta.platforms;
    };
  } ''
    mkdir -p classes
    javac -cp ${classpath} -d classes ${./src}/com/joshammer/keepinv/KeepInvList.java
    cp ${./src}/plugin.yml classes/plugin.yml
    jar --create --file $out -C classes .
  ''
