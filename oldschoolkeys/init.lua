------------------------------------------------------------------------
-- Add some convenient keybindings back.                              --
------------------------------------------------------------------------

local pairs = pairs
local lousy = require("lousy")

local modes = require "modes"

local add_binds = modes.add_binds

module("plugins.oldschoolkeys")

add_binds("normal",
		  {{ "b", "Back", function (w, m) w:back(m.count) end, {count=1}},
			 { "<Mod1-Page_Up>", "Reorder tabs", function (w, m) w.tabs:reorder(w.view, w.tabs:current() - m.count) end, {count=1}},
			 { "<Mod1-Page_Down>", "Reorder tabs", function (w, m) w.tabs:reorder(w.view, (w.tabs:current() + m.count) % w.tabs:count()) end, {count=1}}})


