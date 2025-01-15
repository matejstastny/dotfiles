----------------
---- nvchad ----
----------------

require "core"

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]

if custom_init_path then
	dofile(custom_init_path)
end

require("core.utils").load_mappings()

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
	require("core.bootstrap").gen_chadrc_template()
	require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
vim.opt.rtp:prepend(lazypath)
require "plugins"

-----------------------
--- kireiiii setup ----
-----------------------

local window_width = vim.o.columns

vim.g.mapleader = " " -- This sets the leader key to the spacebar

-- Function to open the dashboard
local function open_dashboard()
   local tree_id = require("nvim-tree.view").get_winnr()
   local tree_size = vim.api.nvim_win_get_width(tree_id)
   vim.o.columns = window_width - tree_size

  -- Open the dashboard using vim.cmd
  vim.cmd("Dashboard")  -- Use vim.cmd to call the Dashboard command

  -- Restore the original width after a short delay
  vim.defer_fn(function()
    vim.o.columns = window_width
  end, 100)  -- Delay in milliseconds
end

-- Set up the notify plugin
-- require("notify").setup({
  -- background_colour = "#000000",  -- Set your desired background color
-- })

-- Set the background highlight for NotifyBackground
vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#000000" })  -- Use the same color or adjust as needed

--------------
-- KEYBINDS --
--------------

-- Keybinding for cutting selected text in visual mode using Backspace
vim.api.nvim_set_keymap('v', '<BS>', '"_d', { noremap = true, silent = true })

-- General LSP keybinds for Java
local opts = { noremap = true, silent = true }

-- Go to definition
vim.api.nvim_set_keymap('n', '<Leader>jd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)

-- Go to references
vim.api.nvim_set_keymap('n', '<Leader>jr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

-- Show hover information (e.g., documentation)
vim.api.nvim_set_keymap('n', '<Leader>jh', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)

-- Rename symbol
vim.api.nvim_set_keymap('n', '<Leader>jr', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

-- List all code actions available at the current cursor position
vim.api.nvim_set_keymap('n', '<Leader>ja', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

-- Format the current buffer
vim.api.nvim_set_keymap('n', '<Leader>jf', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)

-- Show diagnostics for the current line
vim.api.nvim_set_keymap('n', '<Leader>je', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)

-- Go to the next diagnostic (error or warning)
vim.api.nvim_set_keymap('n', '<Leader>jn', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)

-- Go to the previous diagnostic
vim.api.nvim_set_keymap('n', '<Leader>jp', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)

-- Trigger signature help (for method parameters)
vim.api.nvim_set_keymap('n', '<Leader>js', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

-- Organize imports
vim.api.nvim_set_keymap('n', '<Leader>jo', '<cmd>lua require("jdtls").organize_imports()<CR>', opts)

-- Extract a variable or method (JDT specific)
vim.api.nvim_set_keymap('v', '<Leader>jev', '<cmd>lua require("jdtls").extract_variable(true)<CR>', opts)
vim.api.nvim_set_keymap('v', '<Leader>jem', '<cmd>lua require("jdtls").extract_method(true)<CR>', opts)

---------------
-- DASHBOARD --
---------------

-- Automatically open Nvim Tree or focus on the main window based on arguments
local file_not_specified = #vim.fn.argv() == 0
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if file_not_specified then
          vim.cmd("wincmd h")
          open_dashboard()  -- Call the function to open the dashboard
          vim.cmd("wincmd l") -- Focus on the Nvim Tree on the right
        else
          vim.cmd("wincmd h") -- Focus on the main editor on the left
        end
    end,
})

----------
-- TREE --
----------

-- Make a command that expands the whole tree
vim.cmd([[ command! ExpandAll lua require('nvim-tree.api').tree.expand_all() ]])

-- Make a command for the tree to close
vim.cmd([[ command! TreeClose lua require('nvim-tree.api').tree.close() ]])

--Automatically close nvim-tree when closing the last buffer
vim.api.nvim_create_autocmd({"BufEnter"}, {
  callback = function()
    -- Get the number of listed windows (ignores unlisted ones like Noice popups)
    local listed_wins = vim.fn.len(vim.fn.filter(vim.fn.range(1, vim.fn.winnr('$')), 'v:val > 0 && win_gettype(v:val) == ""'))

    -- Check if nvim-tree is the only listed window left
    if listed_wins == 1 and vim.bo.filetype == 'NvimTree' then
      vim.schedule(function()
        -- Save all files before quitting
        vim.cmd("silent! wa")
        -- Close nvim-tree and all windows
        vim.cmd("NvimTreeClose")
        vim.cmd("qa")
      end)
    end
  end
})

--------------
-- BARBECUE --
--------------
-- Show the barbecue tabline
require("barbecue.ui").toggle(true)

