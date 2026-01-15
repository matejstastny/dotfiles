-- greeting screen

return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
        local alpha = require("alpha")

        -- suppress redrawing closed buffers errors
        -- (for example on split create)
        local safe_redraw = alpha.redraw
        alpha.redraw = function(...)
            local ok = pcall(safe_redraw, ...)
            if not ok then return end
        end

        local dashboard = require("alpha.themes.dashboard")
        dashboard.section.header.val = {
            "",
            "",
            "",
            "",
            "",
            "",
            "███╗   ██╗███████╗██╗  ██╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
            "████╗  ██║██╔════╝██║ ██╔╝██╔═══██╗██║   ██║██║████╗ ████║",
            "██╔██╗ ██║█████╗  █████╔╝ ██║   ██║██║   ██║██║██╔████╔██║",
            "██║╚██╗██║██╔══╝  ██╔═██╗ ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
            "██║ ╚████║███████╗██║  ██╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
            "╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
        }

        dashboard.section.buttons.val = {
            dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
            dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
            dashboard.button("SPC ff", "󰱼 > Find File", "<cmd>Telescope find_files<CR>"),
            dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
            dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
            dashboard.button("q", " > Quit NVIM", "<cmd>qa<CR>"),
        }

        alpha.setup(dashboard.opts)
    end,
}
