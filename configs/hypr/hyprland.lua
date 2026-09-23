--  __    __     ______     ______     __     __
-- /\ "-./  \   /\  ___\   /\  __ \   /\ \  _ \ \
-- \ \ \-./\ \  \ \  __\   \ \ \/\ \  \ \ \/ ".\ \
--  \ \_\ \ \_\  \ \_____\  \ \_____\  \ \__/".~\_\
--   \/_/  \/_/   \/_____/   \/_____/   \/_/   \/_/

HOME = os.getenv("HOME")
DOTS = HOME .. "/dotfiles"

local dir = HOME .. "/.config/hypr/modules/"
local function load(m) dofile(dir .. m .. ".lua") end

-- cause of hyprmp slop loading
hl.config({ debug = { suppress_errors = true } })

-- custom hy3
-- https://github.com/matejstastny/hy3/tree/feature/app-aware-autotab
hl.plugin.load(HOME .. "/devel/hy3/build/libhy3.so")

load("monitors")
load("look")
load("input")
load("autostart")
load("binds")
load("rules")
