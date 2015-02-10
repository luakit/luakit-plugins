-- (https://github.com/mason-larobina/luakit/wiki/Play-embedded-video-in-external-player)
----------------------------------------------------------------

local key, buf, cmd = lousy.bind.key, lousy.bind.buf, lousy.bind.cmd

local config = globals.use_video_program or {}

local use_mod = config.use_mod or {}
local use_key = config.use_key or "v"
local use_command = config.use_command or nil

local vid_cmd = config.vid_cmd or "vid"
local vidlist_cmd = config.vid_cmd or "vidlist"

function default_true(x) if x == nil then return true else return x end end

local chain = default_true(config.chain)

-- Whether or not to pop up the window.
local popup_initial = default_true(config.popup_initial)  -- First in list.
local popup = config.popup or false

local geometry = config.geometry or "1366x768"

-- TODO possible to figure out the maximized geometry properly?
--function maximized_geometry() ... end
--function fullscreen_geometry() ... end
   
local which = config.which or "mpv"  -- Allows some pre-defined uses.

local watch_functions = {
   mpv = function(view, uri, finish, pop)
      -- TODO it doesnt listen to `pop`
      if geometry == "fullscreen" then
         luakit.spawn(string.format("mpv --force-window --fs %s", uri), finish)
      else
         luakit.spawn(string.format("mpv --force-window --geometry=%s %s", geometry, uri),
                      finish)
      end
   end,
   cclive = function(view, uri, finish, pop)
      luakit.spawn(string.format("urxvt -e cclive --stream best --filename-format '%%t.%%s' "
               .. "--output-dir %q --exec='mplayer \"%%f\"' %q", os.getenv("HOME") .."/downloads", uri), finish)
   end
}

local vid_function = config.vid_function or watch_functions[which] or watch_function.mpv

local function endprompt(w) return function() w:set_prompt("-- VIDEO ENDED --") end end

local chain_sequence = {}

local function next_in_chain(w, at_end)
   return function()
      table.remove(chain_sequence, 1)
      if #chain_sequence > 0 then
         vid_function(w.view, chain_sequence[1], next_in_chain(w, at_end, popup))
      end
   end
end

local function bind_fun(w)
   local uri = w.view.hovered_uri or w.view.uri
   if uri then
      if chain then
         table.insert(chain_sequence, uri)
         if (#chain_sequence) == 1 then -- One left, get it started.
            vid_function(w.view, uri, next_in_chain(w), popup_initial)
         end
      else
         vid_function(w.view, uri, endprompt(w), popup_initial)
      end
   end
end

if use_key and not (use_key == "not") then
   add_binds("normal", { key(use_mod, use_key, "View video external program", bind_fun) })
end

if use_command and not (use_command == "not") then
   add_binds("normal", { buf(use_command, "View video external program", bind_fun) })
end

if vid_cmd then
   add_cmds({ cmd(vid_cmd, "Use external video program on given URI",
                  function(w,query) vid_function(w.view, query, endprompt) end) })
end

if vidlist_cmd then
   add_cmds({ cmd(vidlist_cmd, "List currently queued video/audio URIs",
                  function(w,query)
                     w:set_prompt(table.concat(chain_sequence, ",\n"))
                  end) })
end
