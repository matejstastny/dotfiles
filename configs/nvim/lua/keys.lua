vim.g.mapleader = " "

local map = vim.keymap.set

-- Insert mode escape
map("i", "jk", "<Esc>")

-- Command shortcut
map("n", ";", ":")

-- File tree
map("n", "<leader>e", "<cmd>Neotree toggle<cr>")

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>",  { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>",   { desc = "Grep text" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>",     { desc = "Buffers" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>",    { desc = "Recent files" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Diagnostics" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>",   { desc = "Help tags" })
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>",     { desc = "Keymaps" })

-- Gitsigns
map("n", "<leader>gg", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Preview hunk" })
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>",   { desc = "Blame line" })
map("n", "]h",         "<cmd>Gitsigns next_hunk<cr>",    { desc = "Next hunk" })
map("n", "[h",         "<cmd>Gitsigns prev_hunk<cr>",    { desc = "Prev hunk" })

-- Obsidian / notes
map("n", "<leader>nt", "<cmd>Obsidian today<cr>")
map("n", "<leader>nn", "<cmd>Obsidian new<cr>")
map("n", "<leader>no", "<cmd>Obsidian quick_switch<cr>")
map("n", "<leader>ns", "<cmd>Obsidian search<cr>")
map("n", "<leader>nb", "<cmd>Obsidian backlinks<cr>")
map("n", "<leader>nl", "<cmd>Obsidian links<cr>")

-- LSP diagnostics
map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Buffer navigation
map("n", "<Tab>",   "<cmd>bnext<cr>")
map("n", "<S-Tab>", "<cmd>bprev<cr>")
