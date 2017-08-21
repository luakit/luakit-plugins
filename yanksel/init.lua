------------------------------------------------------------------------
-- Add yanking selection keybinding (as seen on Wiki ;).              --
------------------------------------------------------------------------

local error = error
local luakit = luakit
local lousy = require("lousy")

local modes = require "modes"

local add_binds = modes.add_binds
local add_cmds = modes.add_cmds

module("plugins.yanksel")

function yank_select(w)
   local text = luakit.selection.primary
   if not text then w:error("Empty selection.") return end
   luakit.selection.clipboard = text
   w:notify("Yanked selection: " .. text)
   luakit.selection.primary = ""		
end

add_binds("normal", {{ "^ys$", "Yank selection", function(w) yank_select(w) end}})

add_cmds({{ ":yanksel", [[Yank selection]], function (w) yank_select(w) end },})
