------------------------------------------------------------------------
-- Add some convenient keybindings back.                              --
------------------------------------------------------------------------

local pairs = pairs
local lousy = require("lousy")
local key, buf, but = lousy.bind.key, lousy.bind.buf, lousy.bind.but
local add_binds, add_cmds = add_binds, add_cmds

module("oldschoolkeys")

local userbindings = {
    -- Normal mode:
    normal = {
        key({},          "b",           function (w, m) w:back(m.count)    end, {count=1}),
        key({"Mod1"},    "Page_Up",     function (w, m) w.tabs:reorder(w.view, w.tabs:current() - m.count) end, {count=1}),
        key({"Mod1"},    "Page_Down",   function (w, m) w.tabs:reorder(w.view, (w.tabs:current() + m.count) % w.tabs:count()) end, {count=1}),
    },
}

function load()
    for modename, modebinds in pairs(userbindings) do
        add_binds(modename, modebinds)
    end
end

load()
