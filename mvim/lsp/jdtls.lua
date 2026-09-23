return {
  cmd = { "jdtls", "-data", vim.fn.stdpath("cache") .. "/jdtls/workspace" },
  filetypes = { "java" },
  root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml", ".git" },
}
