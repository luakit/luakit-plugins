--------------------------------------------------------------------------------
-- © 2012 Mason Larobina (mason-l) <mason.larobina@gmail.com>                 --
-- © 2012 luakit-plugins development team                                     --
-- Source code available under GNU GPLv2 or above                             --
-- Plugins (external add-ons) for  [Luakit browser framework]  modules        --
-- management infrastructure. v0.1.0-pre                                      --
--------------------------------------------------------------------------------

local io = io
local lfs = require("lfs")
local dofile = dofile
local type = type
local table = table
local pairs = pairs
local string = string
local require = require
local print = print
local capi = { luakit = luakit }

module("plugins")

plugins_dir       = capi.luakit.config_dir .. "/plugins/"
rcfile            = plugins_dir .. "rc.lua"
plugins_to_load   = {}
policy            = "manual" -- To prevent automatic load on old rc.lua configs.

-- Get current list of usable plugins.
-- Method: listing all "<plugins_dir>/(*)/init.lua" catalogues and returning
-- a table of their names as we use in rc.lua for manual selection.
-- Additionally, file 'companions' mean auxiliary parts that also could be
-- loaded but are not vital for function of the main extension module.
plugins_list = function(path)
    local plugins_path = path
    if (not path) or (type(path) ~= "string") then
        plugins_path = plugins_dir
    end
    -- Getting list of dirs which contain "init.lua" files:
    local dirs = {}
    
    for entry in lfs.dir(plugins_path) do
        if entry ~= "." and entry ~= ".." then
            local luaentry = plugins_path .. entry .. "/init.lua"
            local attr = lfs.attributes (luaentry)
            if ( type(attr) == "table" ) and ( attr.mode == "file" ) then
                -- Is a loadable one.
                dirs[entry] = true
                do -- Check for companions:
                    local companions = plugins_path .. entry .. "/companions"
                    local attr = lfs.attributes (companions)
                    if ( type(attr) == "table" ) and ( attr.mode == "file" ) then
                        local compfile = io.open (companions, "r")
                        if compfile then
                            for line in compfile:lines() do
                                if line ~= "" then
                                    -- Check for Lua file with companion's name.
                                    local companion = plugins_path .. entry .. "/" .. line .. ".lua"
                                    local attr = lfs.attributes (companion)
                                    if ( type(attr) == "table" ) and ( attr.mode == "file" ) then
                                        -- Module companion file exists.
                                        dirs[entry .. "." .. line] =  true
                                    end
                                end
                            end
                            compfile:close()
                        end
                    end
                end
            end
        end
    end
    
    return dirs
end

rcfile_check = function(filename, fix, valid_plugins)
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
            local default_rc_content_template = [=[
-- This is Luakit.plugins minimal options file.
-- To restore the default configuration simply delete this file
-- and restart luakit

plugins.policy = "automatic" -- Choose "manual" to enable selection below.
                             -- By default is set to "automatic" to load
                             -- everything ignoring manual selection.
plugins.plugins_to_load = {
{plugins}
}
]=]

            local plugin_line_template = [=[    "{pluginid}"]=]
            local line_subs, rc_lines = {}, {}
            for plugin_id, _ in pairs (valid_plugins) do
                local line_subs = { pluginid = plugin_id }
                local plugin_line_template = string.gsub( plugin_line_template, "{(%w+)}", line_subs )
                table.insert( rc_lines, plugin_line_template )
            end
            
            local default_rc_content = string.gsub( default_rc_content_template, "{(%w+)}", { plugins = table.concat(rc_lines, ",\n") } )
            local rc = io.open( filename, "w" )
            rc:write (default_rc_content)
            rc:close ()
            return true
        end
    end
    return false
end

load_plugins = function()
    print ("Initializing plugins: scanning subfolders for valid entries…")
    local valid_plugins = plugins_list (plugins_dir)
    
    print ("plugins: reading rc.lua…")
    if rcfile_check (rcfile, true, valid_plugins) then
        print ("plugins: rc file exists.")
    else
        print ("plugins: rc file does not exist; aborting.")
        error ("plugins: rc file does not exist; aborting.")
    end
    
    -- Read rcfile with plugins list:
    local rc = dofile (rcfile)
    
    -- TODO: Refactor this ugly code into something efficient.
    if policy ~= nil and policy == "automatic" then
        plugins_to_load = {}
        for plugin_id in pairs(valid_plugins) do
            table.insert(plugins_to_load, plugin_id)
        end
    end
    
    -- Import plugins:
    for _, plugin_id in pairs(plugins_to_load) do
        if valid_plugins[plugin_id] then
            print ("Initializing plugin '" .. plugin_id .. "'…")
            require ("plugins." .. plugin_id)
        else
            -- Ignore it.
            print ("Ignore plugin '" .. plugin_id .. "'.")
        end
    end
    
    print ("Initializing plugins: done.")
end

load_plugins()
