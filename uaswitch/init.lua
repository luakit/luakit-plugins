------------------------------------------------------------
-- Simple User Agent string changer v0.0.0-pre            --
-- © 2012 Plaque FCC <Reslayer@ya.ru>                     --
------------------------------------------------------------

local globals   = globals
local string    = string
local type      = type
local assert    = assert
local error     = error
local io        = io
local capi      = { luakit = luakit }
local lousy     = require("lousy")
local util      = lousy.util
local add_binds, add_cmds = add_binds, add_cmds
local lfs       = require("lfs")

module("plugins.uaswitch")

ua_alias_default = "default"

ua_strings = {
    original = string.rep(globals.useragent, 1),
    fakes = {
        ["inferfox"]        = "Mozilla/6.0 (compatible; AppleWebKit/latest; like Gecko/20120405; };-> infernal_edition:goto-hell) Firefox/666",
        ["firefox_15"]      = "Mozilla/5.0 (Windows NT 6.1; rv:15.0) Gecko/20120427 Firefox/15.0a1",
        ["firefox_14"]      = "Mozilla/5.0 (Windows NT 6.1; rv:14.0) Gecko/20120405 Firefox/14.0a1",
        ["firefox_13"]      = "Mozilla/5.0 (Windows NT 6.1; rv:12.0) Gecko/20120403211507 Firefox/12.0",
        ["firefox_11"]      = "Mozilla/5.0 (Windows NT 6.1; rv:11.0) Gecko Firefox/11.0",
        ["ie10"]            = "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)",
        ["camino"]          = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X 10.6; en; rv:1.9.2.14pre) Gecko/20101212 Camino/2.1a1pre (like Firefox/3.6.14pre)",
        ["safari"]          = "Mozilla/5.0 (Macintosh; PPC Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.3 Safari/534.53.10",
    },
}


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