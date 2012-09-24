------------------------------------------------------------------------
-- Luakit Plugins general purpose library.                            --
-- © 2012 Plaque FCC <Reslayer@ya.ru>                                 --
------------------------------------------------------------------------

local io        = io
local string    = string
local plugins   = require("plugins")


module("plugins.lib")

local unescape_html_subst = {
    ["%3A"] = ":",
    ["%2F"] = "/",
    ["%20"] = " ",
    -- To be continued! ;’D
}

function unescape(text)
    return text and text:gsub("%%%x%x", unescape_html_subst)
end

function basename(URI)
    local result = nil
    local fh = io.popen("basename " .. URI, "r")
    for line in fh:lines() do
        result = line
    end
    fh:close()
    return result
end

function dirname(URI)
    local result = nil
    local fh = io.popen("dirname " .. URI, "r")
    for line in fh:lines() do
        result = line
    end
    fh:close()
    return result
end