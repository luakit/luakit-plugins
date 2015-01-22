-- Autoscroll script for luakit (luakit.org).
-- Originally by @mason-larobina and then @alexdantas
-- (https://gist.github.com/mason-larobina/726550)
-- (https://gist.github.com/alexdantas/7987616)
--
-- Install instructions:
--  * Add to rc.lua before window spawning code
--  Or
--  * Save to $XDG_CONFIG_HOME/luakit/autoscroll.lua and
--    add `require "autoscroll"` to your rc.lua
----------------------------------------------------------------

local buf, key = lousy.bind.buf, lousy.bind.key

local config = globals.autoscroll

local start_buf = config.start_buf or "^,a$"

local stop_mod = config.stop_modifier or {}
local stop_key = config.stop_key or ","

local scroll_step = config.autoscroll_step or 1 -- globals.scroll_step -- (too fast)
local page_step = globals.page_step or config.page_step or 1.0

local accel = config.acceleration or 5

add_binds("normal", {
			 -- Start autoscroll with a (previously ,a)
       buf(start_buf, "Start autoscroll", function (w) w:set_mode("autoscroll") end),
})

add_binds("autoscroll", {
			 -- Increase scrolling speed
			 key({}, "+", function (w)
					w.autoscroll_timer:stop()
					w.autoscroll_timer.interval = math.max(5, w.autoscroll_timer.interval - accel)
          w:set_prompt(string.format("-- AUTOSCROLL MODE (%d) --", w.autoscroll_timer.interval))
					w.autoscroll_timer:start()
			 end),

			 -- Decrease scrolling speed
			 key({}, "-", function (w)
					w.autoscroll_timer:stop()
					w.autoscroll_timer.interval = w.autoscroll_timer.interval + accel
          w:set_prompt(string.format("-- AUTOSCROLL MODE (%d) --", w.autoscroll_timer.interval))
					w.autoscroll_timer:start()
			 end),

			 -- Default page scroll keybindings,
			 -- so we can still scroll while autoscrolling.
			 key({}, "Page_Down", "Scroll page down.",
           function (w) w:scroll{ ypagerel =  page_step } end),

			 key({}, "Page_Up", "Scroll page up.",
           function (w) w:scroll{ ypagerel = -page_step } end),

       buf(start_buf, "Stop autoscroll", function (w) w:set_mode("normal") end),
})


if stop_key and not stop_key == "not" then
   add_binds("autoscroll", {
                key(stop_mod, stop_key, "Stop autoscroll",
                    function (w) w:set_mode("normal") end),
                           })
end

new_mode("autoscroll", {
			-- Start autoscroll timer
			enter = function (w)
			   local t = timer{interval=50}
         w:set_prompt("-- AUTOSCROLL MODE (50) --")
			   t:add_signal("timeout", function ()
							   w:scroll { yrel = scroll_step }
			   end)
			   w.autoscroll_timer = t
			   t:start()
			end,

			-- Stop autoscroll timer
			leave = function (w)
			   if w.autoscroll_timer then
				  w.autoscroll_timer:stop()
				  w.autoscroll_timer = nil
			   end
			end,
})
