local M = {}

M.dap = {
  plugin = true,
  n = {
    ["<leader>db"] = {
      "<cmd> DapToggleBreakpoint <CR>",
      "Add breakpoint line",
    },
    ["<leader>dr"] = {
      "<cmd> DapContinue <CR>",
      "Start or continue the debugger"
    }
  }
}

M.java = {
  plugin = true,
  n = {
    ["<leader>jd"] = {
      action = "Go to definition",
      description = "Jump to the definition of the symbol under the cursor."
    },
    ["<leader>jr"] = {
      action = "Go to references",
      description = "Show references for the symbol under the cursor."
    },
    ["<leader>jh"] = {
      action = "Show hover information",
      description = "Display documentation for the symbol under the cursor."
    },
    ["<leader>jrn"] = {
      action = "Rename symbol",
      description = "Rename the symbol under the cursor."
    },
    ["<leader>ja"] = {
      action = "List code actions",
      description = "Show available code actions at the current cursor position."
    },
    ["<leader>jf"] = {
      action = "Format buffer",
      description = "Format the current buffer according to Java standards."
    },
    ["<leader>je"] = {
      action = "Show diagnostics",
      description = "Open a floating window with diagnostics for the current line."
    },
    ["<leader>jn"] = {
      action = "Go to next diagnostic",
      description = "Jump to the next diagnostic (error or warning)."
    },
    ["<leader>jp"] = {
      action = "Go to previous diagnostic",
      description = "Jump to the previous diagnostic (error or warning)."
    },
    ["<leader>js"] = {
      action = "Signature help",
      description = "Show parameter hints for the method/function under the cursor."
    },
    ["<leader>jo"] = {
      action = "Organize imports",
      description = "Organize and optimize imports in the current Java file."
    },
    ["<leader>jev"] = {
      action = "Extract variable",
      description = "Extract the selected expression into a variable."
    },
    ["<leader>jem"] = {
      action = "Extract method",
      description = "Extract the selected code block into a method."
    },
  }
}

return M

