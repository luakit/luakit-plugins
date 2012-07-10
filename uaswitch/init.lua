------------------------------------------------------------
-- Simple User Agent string changer v0.0.0-pre            --
-- © 2012 Plaque FCC <Reslayer@ya.ru>                     --
------------------------------------------------------------

local globals   = globals
local string    = string
local type      = type
local dofile    = dofile
local assert    = assert
local error     = error
local io        = io
local capi      = { luakit = luakit }
local lousy     = require("lousy")
local util      = lousy.util
local add_binds, add_cmds = add_binds, add_cmds
local lfs       = require("lfs")
local plugins   = plugins

module("plugins.uaswitch")

ua_alias_default = "default"

ua_strings_file = plugins.plugins_dir .. "uaswitch/ua_strings.lua"

ua_strings = {}

function load_ua_strings()
    ua_strings = {
        original = string.rep(globals.useragent, 1),
        fakes = {}
    }
    dofile(ua_strings_file)
end

function switch_to(alias)
    if (not alias) then
        alias = ua_alias_default
    end
    assert(type(alias) == "string", "user agent switch: invalid user agent alias")
    local useragent = nil
    io.stdout:write("uaswitcher: Requested change to '" .. alias .."'.\n")
    if (alias == ua_alias_default) then
        useragent = ua_strings.original
    else
        useragent = ua_strings.fakes[alias]
    end

    if (useragent) then
        io.stdout:write("uaswitcher: Change to '" .. useragent .."'.\n")
        globals.useragent = string.rep(useragent, 1)
        return
    else
        error("uaswitcher: unknown alias '" .. alias .. "'")
    end
end

function load()
    load_ua_strings()
    -- switch_to(ua_alias_default)
    switch_to("inferfox") -- And let them choke! ;'D
end

-- Add commands.
local cmd = lousy.bind.cmd
add_cmds({
    cmd({"user-agent", "ua"}, function (w, a)
        switch_to(a)
    end),
})

-- Initialise module
load()
