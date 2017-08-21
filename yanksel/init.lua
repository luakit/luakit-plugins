------------------------------------------------------------------------
-- Add yanking selection keybinding (as seen on Wiki ;).              --
------------------------------------------------------------------------
local luakit = luakit
local lousy = require("lousy")
local modes = require "modes"
local add_binds = modes.add_binds
local add_cmds = modes.add_cmds

local _M = {}

local actions = { 
   yank_select = {
	  desc = "Yank selection.",
	  func = function (w)
		 local text = luakit.selection.primary
		 if not text then w:error("Empty selection.") return end
		 luakit.selection.clipboard = text
		 w:notify("Yanked selection: " .. text)
		 luakit.selection.primary = ""
	  end,
   }
}

add_binds("normal", {{ "^ys$", actions.yank_select }})

add_cmds({{ ":yanksel", actions.yank_select },})

return _M
