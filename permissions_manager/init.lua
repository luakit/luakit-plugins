--- permissions manager.
--
-- # Capabilities
--
-- # Usage
--
-- * Add `require "permissions_manager"` to your `config.rc`.
-- * Copy example of permissions.cfg to ~/.local/share/luakit/permissions.cfg
-- * Edit its content according to your needs
--
-- # Troubleshooting
--
-- # Files and Directories
--
-- @module permissions_manager
-- @author Serg Kozhemyakin <serg.kozhemyakin@gmail.com>
-- @copyright 2017-2018 Serg Kozhemyakin <serg.kozhemyakin@gmail.com>

local webview = require ("webview")
local lousy = require("lousy")

local function to_grant_or_not_to_grant(cfg, uri)
    local grant = nil
    local scheme = uri.scheme
    local host = uri.host
    local port = uri.port
    local default = false

    if cfg then
        default = cfg['default'] or 'denied' -- by default deny or requests
        local key
        if default == 'allowed' then
            default = true
            key = 'denied'
        else
            default = false
            key = 'allowed'
        end
        cfg = cfg[key]
        if not cfg then return grant end

        local origin = scheme.."://"..host..":"..port;
        for _,v in ipairs(cfg) do
            if string.match(origin, v) then
                grant = not default
                break
            end
            if grant ~= nil then break end
        end
    end
    -- check for default value if there's no host specific value
    return grant == nil and default or grant
end

local function check_permission_request(view, what, params)
    local grant = nil
    local uri = lousy.uri.parse(view.uri)
    msg.info("Checking permission '"..what.."' for '"..uri.scheme.."://"..uri.host..":"..uri.port)

    local config = luakit.data_dir .. '/permissions.cfg'
    msg.info("Loading config file '"..config.."'")

    local f,r = io.open(config, "r")
    if f then
        local cfg = f:read("*all")
        local permissions = nil
        local code, message = loadstring("return "..cfg)
        f:close()
        if message then
            msg.error("Loading cfg failed: "..message)
            return false
        else
            permissions = code()
        end
        if not permissions or not permissions[what] then
            msg.warn("There's no key '"..what.."' in loaded permissions")
            return false
        end
        permissions = permissions[what]
        if params then
            if type(params) == 'table' then
                for k,_ in pairs(params) do
                    grant = to_grant_or_not_to_grant(permissions[params][k], uri)
                    if grant ~= nil and not grant then break end
                end
            else
                grant = to_grant_or_not_to_grant(permissions[params], uri)
            end
        else
            grant = to_grant_or_not_to_grant(permissions, uri)
        end
    else
        msg.error("Failed to open config file: "..r)
    end

    grant = grant == nil and false or grant
    msg.info("Permission '"..what.."' for '"..uri.scheme.."://"..uri.host..":"..uri.port.." was "..(grant and "granted" or "denied"))
    return grant
end

webview.add_signal("init", function (view)
    view:add_signal("permission-request", check_permission_request)
end)

-- vim: et:sw=4:ts=8:sts=4:tw=80
