plugins {
    `java-library`
}

group = "us.malleum"
version = "1.1.0"

java {
    toolchain.languageVersion = JavaLanguageVersion.of(21)
}

repositories {
    mavenCentral()
    // paper-api
    maven("https://repo.papermc.io/repository/maven-public/")
    // Origins-Reborn (closed-source; Modrinth serves the release jars as a maven repo)
    maven("https://api.modrinth.com/maven")
}

dependencies {
    compileOnly("io.papermc.paper:paper-api:1.21.10-R0.1-SNAPSHOT")
    compileOnly("maven.modrinth:origins-reborn:2.10.9")
}

tasks.processResources {
    // expand() values aren't task inputs by default; without this a version
    // bump leaves a stale version inside plugin.yml on incremental builds.
    inputs.property("version", version)
    filesMatching("plugin.yml") {
        expand("version" to version)
    }
}

tasks.jar {
    archiveBaseName = "Waverider-Origin"
}
