-- (https://github.com/mason-larobina/luakit/wiki/Play-embedded-video-in-external-player)
----------------------------------------------------------------

local key, buf, cmd = lousy.bind.key, lousy.bind.buf, lousy.bind.cmd

local config = globals.use_video_program or {}

local use_mod = config.use_mod or {}
local use_key = config.use_key or "v"
local use_command = config.use_command or nil
local vid_cmd = config.vid_cmd or "vid"

local geometry = config.geometry or "1366x768"

-- TODO possible to figure out the maximized geometry properly?
--function maximized_geometry() ... end
--function fullscreen_geometry() ... end
   
local which = config.which or "mpv"  -- Allows some pre-defined uses.

local watch_functions = {
   mpv = function(view, uri, finish)
      if geometry == "fullscreen" then
         luakit.spawn(string.format("mpv --force-window --fs %s", uri), finish)
      else
         luakit.spawn(string.format("mpv --force-window --geometry=%s %s", geometry, uri, finish))
      end
   end,
   cclive = function(view, uri, finish)
      luakit.spawn(string.format("urxvt -e cclive --stream best --filename-format '%%t.%%s' "
               .. "--output-dir %q --exec='mplayer \"%%f\"' %q", os.getenv("HOME") .."/downloads", uri), finish)
   end
}

local vid_function = config.vid_function or watch_functions[which] or watch_function.mpv

local function endprompt() w:set_prompt("-- VIDEO ENDED --") end

local function activate (w)
   local uri = w.view.hovered_uri or w.view.uri
   if uri then
      vid_function(w.view, uri, endprompt)
   end
end

if use_key and not (use_key == "not") then
   add_binds("normal", { key(use_mod, use_key, "View video external program", activate) })
end

if use_command and not (use_command == "not") then
   add_binds("normal", { buf(use_command, "View video external program", activate) })
end

if vid_cmd then
   add_cmds({ cmd(vid_cmd, "Use external video program on given URI",
                  function(w,query) vid_function(w.view, query, endprompt) end) })
end
