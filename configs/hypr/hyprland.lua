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

load("env")
load("monitors")
load("look")
load("input")
load("autostart")
load("binds")
load("rules")
