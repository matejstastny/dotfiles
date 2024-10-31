local jdtls = require("jdtls")

-- Adjust the path to the jar file according to your installation
local jar_path = vim.fn.expand("~/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar")
--local cmd = { "java", "-jar", jar_path }


-- Find the root directory of the Java project
local root_dir = vim.fs.dirname(vim.fs.find({ "gradlew", ".git", "mvnw" }, { upward = true })[1])

-- Configure jdtls
local config = {
  cmd = cmd,
  root_dir = root_dir,
  settings = {
    java = {
      home = os.getenv("JAVA_HOME"),  -- Set this to your actual Java home path
    },
  },
}
-- Start or attach the jdtls server
jdtls.start_or_attach(config)
