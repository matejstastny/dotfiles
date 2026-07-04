local dir = os.getenv("HOME") .. "/.config/hypr/modules/"
local function load(m) dofile(dir .. m .. ".lua") end

load("env")
load("monitors")
load("look")
load("input")
load("autostart")
load("binds")
load("rules")
