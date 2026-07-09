--  __    __     ______     ______     __     __
-- /\ "-./  \   /\  ___\   /\  __ \   /\ \  _ \ \
-- \ \ \-./\ \  \ \  __\   \ \ \/\ \  \ \ \/ ".\ \
--  \ \_\ \ \_\  \ \_____\  \ \_____\  \ \__/".~\_\
--   \/_/  \/_/   \/_____/   \/_____/   \/_/   \/_/

local dir = os.getenv("HOME") .. "/.config/hypr/modules/"
local function load(m) dofile(dir .. m .. ".lua") end

load("env")
load("monitors")
load("look")
load("input")
load("autostart")
load("binds")
load("rules")
