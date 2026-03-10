return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            dashboard = {
                preset = {
                    header = [[

      ∧＿∧
     (｡•́ω•̀｡)  ♡
      づ ♡
     ～   ～

  n  e  o  v  i  m]],
                    keys = {
                        { icon = " ", key = "f", desc = "Find File",    action = ":Telescope find_files" },
                        { icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
                        { icon = " ", key = "g", desc = "Grep Text",    action = ":Telescope live_grep" },
                        { icon = " ", key = "n", desc = "New File",     action = ":ene | startinsert" },
                        { icon = " ", key = "l", desc = "Lazy",        action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Quit",        action = ":qa" },
                    },
                },
                sections = {
                    { section = "header" },
                    { section = "keys", gap = 1, padding = 1 },
                    { section = "startup" },
                },
            },
        },
    },
}
