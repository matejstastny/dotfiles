-- Main ------------------------------------------------------------------------

require("daarlin.core")
require("daarlin.lazy")

-- Sidebar ignoring ------------------------------------------------------------
-- Close Neovim if the only remaining windows are "sidebars"

vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("LazyVim_CloseWithQ", { clear = true }),
    callback = function()
        local wins = vim.api.nvim_list_wins()
        if #wins == 1 then
            local buftype = vim.bo.buftype
            local ft = vim.bo.filetype

            local sidebars = {
                "help",
                "qf",
                "NvimTree",
                "neo-tree",
                "trouble",
                "spectre_panel",
                "startuptime",
                "Outline",
            }

            if buftype == "nofile" or vim.tbl_contains(sidebars, ft) then
                vim.cmd("quit")
            end
        end
    end,
})
