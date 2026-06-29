return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            dashboard = {
                preset = {
                    header = table.concat({
                        "           ╱|、          ",
                        "         (˚ˎ 。7         ",
                        "          |、˜〵          ",
                        "          じしˍ,)ノ        ",
                        "                        ",
                        "  ✦ ✧  hello gorgeous~  ✧ ✦",
                    }, "\n"),
                    keys = {
                        { key = "f", desc = "♡  find file",    action = ":Telescope find_files" },
                        { key = "r", desc = "✦  recent files", action = ":Telescope oldfiles" },
                        { key = "g", desc = "✧  grep text",    action = ":Telescope live_grep" },
                        { key = "e", desc = "   file tree",    action = ":Neotree toggle" },
                        { key = "n", desc = "~  new file",      action = ":ene | startinsert" },
                        { key = "l", desc = "   lazy",         action = ":Lazy" },
                        { key = "q", desc = "×  quit",          action = ":qa" },
                    },
                },
                sections = {
                    { section = "header" },
                    { section = "keys",   gap = 1, padding = 1 },
                    { section = "startup" },
                },
            },
        },
    },
}
