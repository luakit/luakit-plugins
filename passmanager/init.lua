--- passmanager module.
--
-- This module allows to use pass (www.passwordstore.org) as password manager in luakit
-- plus it have integrated passhash generator (slightly modified version of
-- https://milliways.cryptomilk.org/passhash.html)
--
-- # Capabilities
--
-- Plugin assumes that first line in pass record is password and second line is login.
-- If your pass records have different structure then don't use this plugin because it will overwrite
-- first 2 line unconditionally during password update.
--
-- # Usage
--
-- * Import your existing passwords from firefox to pass using https://github.com/Unode/firefox_decrypt/#readme
--   or setup pass without importing password.
--
-- * Add `require "passmanager"` to your `config.rc`.
--
-- * After loading of any page it will be inspected and if
--   page has form(s) with login/password fields plugin query for all existing credentials
--   registered for this site in pass manager (query like 'pass web/site/login1', 'pass web/site/login1'
--   and 'pass web/site'). and attachs several callbacks to login/password fields.
--
--   Login/passwords fields will be prefilled with first (shortest) login and corresponding password
--
--   In login field you can use Up and Down keys for scrolling over all know logins
--
--   When login field lost focus then password field(s) will be filled with corresponding values
--   (if there's password for entered login)
--
--   In password filed you can press:
--   *) Alt-s -- shows/hides content of password field
--   *) Alt-g -- opens passhash generator
--
-- * Before submitting form plugin checks entered login and password and if:
--   *) there's no yet such login registered for this site then new pass record created for it
--   *) password is different from existing - then updating pass record with new password for login
--   both steps require interactive confirmation from user
--   *) forms with empty login and/or password are ignored and pass record doesn't updated/created
--
-- # Troubleshooting
--
--   tricky login forms may not work
--   probably a lot of bug but feel free to report them :)
--
-- # Files and Directories
--
-- @module passmanager
-- @author Serg Kozhemyakin <serg.kozhemyakin@gmail.com>
-- @copyright 2017-2018 Serg Kozhemyakin <serg.kozhemyakin@gmail.com>

local window = require("window")
local new_mode = require("modes").new_mode
local modes = require("modes")
local lousy = require("lousy")
local wm = require_web_module('plugins/passmanager/passmanager_wm')
local lfs = require("lfs")

local web_root = 'web'

local function fetch_credentials_for_domain(domain)
    local credentials = {}
    local pwd_store = os.getenv('PASSWORD_STORE_DIR') or os.getenv('HOME')..'/.password-store'
    local pwd = (web_root and web_root..'/' or '')..domain
    local path = pwd_store..'/'..pwd
    local attr = lfs.attributes(path)
    if attr then
        if attr.mode == 'directory' then
            for f in lfs.dir(path) do
                if string.sub(f, 1, 1) ~= '.' then
                    f = string.gsub(f, '%.gpg$', '')
                    local p = io.popen('pass '..pwd..'/'..f..' 2>/dev/null')
                    local password = p:read()
                    local login = p:read()
                    if login and password then
                        table.insert(credentials, {password = password, login = login, file = pwd..'/'..f})
                    end
                    p:close()
                end
            end
        end
    else
        attr = lfs.attributes(path..'.gpg')
        if attr  and attr.mode == 'file' then
            local p = io.popen('pass '..pwd)
            local password = p:read()
            local login = p:read()
            if login and password then
                table.insert(credentials, {password = password, login = login, file = pwd})
            end
            p:close()
        end
    end
    -- if no credentials for this domain then let's try to fetch
    -- them for parent one
    if not #credentials then
        local dot = string.find(domain, '%.')
        if dot then
            credentials = fetch_credentials_for_domain(string.sub(domain, dot+1))
        end
    end
    table.sort(credentials, function(a,b) return #a.login < #b.login end)
    return credentials
end

local function update_pass_record(login, password, file, force)
    -- first let's read existing pass entry, if it exists
    local p = io.popen('pass '..file..' 2>/dev/null')
    local entry = {}
    for line in p:lines() do
        table.insert(entry, line)
    end
    p:close()

    -- update login/password entries and preserve all other entries
    entry[1] = password
    entry[2] = login

    -- write updated pass entry
    p = io.popen('pass insert -m '..(force and '-f ' or '')..file..' >/dev/null 2>&1', 'w')
    for _, line in ipairs(entry) do
        p:write(line.."\n")
    end
    p:close()
end

local _op = setmetatable({}, {__mode = 'k'});
new_mode("passmanager-ask-confirmation", {
    enter = function (w, confirmation_msg, lock_file, login, password, file, force)
        w:warning(confirmation_msg..' (y/n)', false)
        _op[w] = {lock_file = lock_file, login = login, password = password, file = file, force = force}
    end,

    leave = function (w)
        os.remove(_op[w].lock_file)
        _op[w] = nil
    end,
})

local function w_from_view_id(view_id)
    assert(type(view_id) == "number", type(view_id))
    for _, w in pairs(window.bywidget) do
        if w.view.id == view_id then return w end
    end
end

modes.add_binds("passmanager-ask-confirmation", {
    { "y", "Answer 'Yes' on confirmation.", function (w)
        update_pass_record(_op[w].login, _op[w].password, _op[w].file, _op[w].force)
        w:set_mode()
    end },
    { "n", "Answer 'No' on confirmation.", function (w) w:set_mode() end },
    { "<Escape>", "Answer 'No' on confirmation.", function (w) w:set_mode() end },
})

wm:add_signal('update-pass-for-login', function (_, page, lock_file, domain, login, password, file)
    local w = w_from_view_id(page)
    w:set_mode("passmanager-ask-confirmation", '**'..domain..'**: update this login: "'..login..'" with password: "'..password..'"?',
        lock_file, login, password, file, true)
end)

wm:add_signal('create-pass-for-login', function (_, page, lock_file, domain, login, password)
    local w = w_from_view_id(page)
    local file = (web_root and web_root..'/' or '')..domain..'/'..login
    w:set_mode("passmanager-ask-confirmation", '**'..domain..'**: remember this login: "'..login..'" and password: "'..password..'"?',
        lock_file, login, password, file, false)
end)

wm:add_signal('get-credentials-for-uri', function (_, page, domain)
    local credentials = fetch_credentials_for_domain(domain)
    wm:emit_signal(page, 'get-credentials-for-uri-reply', {credentials, domain})
end)

local plugin_location = luakit.config_dir..'/plugins/passmanager'
wm:add_signal('get-plugin-configuration', function (_, page)
    wm:emit_signal(page, 'get-plugin-configuration-reply', plugin_location)
end)

-- vim: et:sw=4:ts=8:sts=4:tw=80
