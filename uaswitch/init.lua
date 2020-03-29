------------------------------------------------------------
-- Simple User Agent string changer v0.1.0                --
-- © 2012 Plaque FCC <Reslayer@ya.ru>                     --
------------------------------------------------------------

local string    = string
local type      = type
local dofile    = dofile
local assert    = assert
local error     = error
local pairs     = pairs
local ipairs    = ipairs
local io        = io
local settings  = require("settings")
local plugins   = require ("plugins")
local window    = require ("window")
local modes	= require ("modes")



local ua_strings_file = plugins.plugins_dir .. "uaswitch/ua_strings.lua"
local _M = {}
_M.ua_strings = {}
_M.hide_box = false

-- Refresh open filters views (if any)
function update_views()
    for _, w in pairs(window.bywidget) do
        for _, v in ipairs(w.tabs.children) do
            v.user_agent = settings.webview.user_agent
        end
    end
end

function load_ua_strings()
    _M.ua_strings = {
        original = string.rep(settings.webview.user_agent, 1),
	fakes = dofile (ua_strings_file)
    }
end

function switch_to(alias)
    if (not alias) then
        alias = "default"
    end
    assert(type(alias) == "string", "user agent switch: invalid user agent alias")
    local useragent = nil
    io.stdout:write("uaswitcher: Requested change to '" .. alias .."'.\n")
    if (alias == "default") then
        useragent = _M.ua_strings.original
    else
        useragent = _M.ua_strings.fakes[alias]
    end

    if (useragent) then
        io.stdout:write("uaswitcher: Change to '" .. useragent .."'.\n")
        settings.webview.user_agent = string.rep(useragent, 1)
        update_views()
        return
    else
        error("uaswitcher: unknown alias '" .. alias .. "'")
    end
end


-- Add commands.
modes.add_cmds({
	{ ":user-agent", "Set user-agent string", function (w, a)
	    switch_to(a.arg)
	end},
})

load_ua_strings()
return _M
