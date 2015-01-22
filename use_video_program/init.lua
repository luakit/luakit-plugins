-- (https://github.com/mason-larobina/luakit/wiki/Play-embedded-video-in-external-player)
----------------------------------------------------------------

local key, buf, but = lousy.bind.key, lousy.bind.buf, lousy.bind.but

local config = globals.use_video_program or {}

local use_mod = config.use_mod or {}
local use_key = config.use_key or "v"
local use_command = config.use_command or nil

local geometry = config.geometry or "1366x768"
   
local which = config.which or "mpv"  -- Allows some pre-defined uses.

local watch_functions = {
   mpv = function(view, uri, finish)
      if geometry == "fullscreen" then
         luakit.spawn(string.format("mpv --fs %s", uri), finish)
      else
         luakit.spawn(string.format("mpv --geometry=%s %s", geometry, uri, finish))
      end
   end,
   cclive = function(view, uri)
      luakit.spawn(string.format("urxvt -e cclive --stream best --filename-format '%%t.%%s' "
               .. "--output-dir %q --exec='mplayer \"%%f\"' %q", os.getenv("HOME") .."/downloads", uri), finish)
   end
}

local use_function = config.use_function or watch_functions[which] or watch_function.mpv

function activate (w)
   local uri = w.view.hovered_uri or w.view.uri
   if uri then
      use_function(w.view, uri,
                   function() w:set_prompt("-- VIDEO ENDED --") end)
   end
end

if use_key and not (use_key == "not") then
   add_binds("normal", { key(use_mod, use_key, "View video external program",
                             function(w) activate(w) end), })
end

if use_command and not (use_command == "not") then
   add_binds("normal", { buf(use_command, "View video external program",
                             function(w) activate(w) end), })
end
