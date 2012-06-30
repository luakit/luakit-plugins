--------------------------------------------------------------------------------
-- © 2012 Mason Larobina (mason-l) <mason.larobina@gmail.com>                 --
-- © 2012 luakit-plugins development team                                     --
-- Source code available under GNU GPLv2 or above                             --
-- Plugins (external add-ons) for  [Luakit browser framework]  modules        --
-- management infrastructure. v0.0.0-pre                                      --
--------------------------------------------------------------------------------

local io = io
local lfs = require("lfs")
local dofile = dofile
local type = type
local pairs = pairs
local require = require
local capi = { luakit = luakit }

module("plugins")

plugins_dir = capi.luakit.config_dir .. "/plugins/"
rcfile      = plugins_dir .. "rc.lua"

rcfile_check = function(filename, fix)
    -- Check if file name is a non-empty string:
    if not filename or type(filename) ~= "string" or filename > "" then
        -- error("plugins: incorrect rcfile path given.")
        filename = rcfile
    end
    
    -- Now test if the file exists:
    rcfile_mode, err_msg = lfs.attributes(filename, "mode")
    if rcfile_mode and rcfile_mode == "file" then
        -- Yes, exists. Do not check its content.
        return true
    else
        -- Can restore the default list of plugins if `fix’ is not false or nil.
        if not fix then
            return false
        else
            local default_rc_content = [=[plugins.plugins_to_load = { "adblock", "uaswitch", }]=]
            local rc = io.open(filename, "w")
            rc:write(default_rc_content)
            rc:close()
            return true
        end
    end
    
end

load_plugins = function()
    io.stdout:write("Initializing plugins: reading rc.lua…\n")
    
    if rcfile_check(rcfile, true) then
        io.stdout:write("plugins: rc file exists.\n")
    else
        io.stdout:write("plugins: rc file does not exist; aborting.\n")
        error("plugins: rc file does not exist; aborting.")
    end
    -- Read rcfile with plugins list:
    
    
    
    local rc = dofile(rcfile)
    
    -- Import plugins:
    for _, plugin_id in pairs(plugins_to_load) do
        io.stdout:write("Initializing plugin '" .. plugin_id .. "'…\n")
        require("plugins." .. plugin_id)
    end
    
    io.stdout:write("Initializing plugins: done.\n")
end

load_plugins()
