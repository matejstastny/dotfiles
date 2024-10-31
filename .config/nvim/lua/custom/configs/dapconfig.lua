local dap = require('dap')

dap.adapters.cpp = {
  type = 'server',
  port = "${port}",
  executable = {
    command = '/Users/matejstastny/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb',
    args = {"--port", "${port}"},
  }
}

dap.configurations.cpp = {
  {
    name = "Launch",
    type = "cpp", -- matches the adapter
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  }
}
