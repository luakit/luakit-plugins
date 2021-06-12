--- passmanager web module.
--
-- # Capabilities
--
-- # Usage
--
-- For usage information check init.lua
--
-- # Troubleshooting
--
-- # Files and Directories
--
-- @module passmanager.passmanager_wm
-- @author Serg Kozhemyakin <serg.kozhemyakin@gmail.com>
-- @copyright 2017-2018 Serg Kozhemyakin <serg.kozhemyakin@gmail.com>

local ui = ipc_channel('plugins/passmanager/passmanager_wm')
local luakit = require('luakit')
local lousy = require("lousy")
local clone = lousy.util.table.clone
local hasitem = lousy.util.table.hasitem
local filter = lousy.util.table.filter_array
local join = lousy.util.table.join
local keys = lousy.util.table.keys
local lfs = require("lfs")

-- list of known credentials and forms per page
local _page_credentials = setmetatable({}, { __mode = "k" })
local _page_forms = setmetatable({}, { __mode = "k" })

local _plugin_location = nil

local function uri_to_domain(uri)
    local _uri = lousy.uri.parse(uri)
    local domain = _uri.host
    if _uri.port and _uri.port ~= 80 and _uri.port ~= 443 then
        domain = domain .. ":" .. _uri.port
    end
    return domain
end

local function find_login(tbl, login)
    for _, p in ipairs(tbl) do
        if p.login == login then
            return p
        end
    end
    return nil
end

local function find_login_index(tbl, login)
    for i, p in ipairs(tbl) do
        if p.login == login then
            return i
        end
    end
    return nil
end

-- random string generation borrowed from lua-wiki
local Chars = {}
for Loop = 0, 255 do
    Chars[Loop+1] = string.char(Loop)
end
local String = table.concat(Chars)

local Built = {['.'] = Chars}

local AddLookup = function(CharSet)
    local Substitute = string.gsub(String, '[^'..CharSet..']', '')
    local Lookup = {}
    for Loop = 1, string.len(Substitute) do
        Lookup[Loop] = string.sub(Substitute, Loop, Loop)
    end
    Built[CharSet] = Lookup

    return Lookup
end

local function random_string(Length, CharSet)
    -- Length (number)
    -- CharSet (string, optional); e.g. %l%d for lower case letters and digits

    CharSet = CharSet or '%l%d'

    if CharSet == '' then
        return ''
    else
        local Result = {}
        local Lookup = Built[CharSet] or AddLookup(CharSet)
        local Range = #Lookup

        for Loop = 1,Length do
            Result[Loop] = Lookup[math.random(1, Range)]
        end

        return table.concat(Result)
    end
end
-- end of random string generation

local function _eval_js_on_element(page, element, js)
    local reset = false
    if not element.attr.id or element.attr.id == '' then
        element.attr.id = random_string(32)
        reset = true
    end
    local ret = page:eval_js(string.format("(function(element) { return element.%s })(document.getElementById('%s'))", js, element.attr.id))
    if reset then
        element.attr.id = ''
    end
    return ret
end

local function _input_select_range(page, input, from, to)
    local direction = 'forward'
    if not from or not to then return end
    if from > to then
        from, to = to, from
        direction = 'backward'
    end
    _eval_js_on_element(page, input, string.format("setSelectionRange(%i,%i,'%s')", from, to, direction))
end

local function _input_field_input_cb(page, tbl)
    local input = tbl.target
    local txt = input.value
    if txt ~= "" then
        for _, p in ipairs(_page_credentials[page][1]) do
            local login = p.login
            if string.find(login, txt) == 1 then
                input.value = login
                _input_select_range(page, input, #txt, #login, 'backward')
                break
            end
        end
    end
end

local function _input_field_keydown_cb(page, tbl)
    -- handle Up and Down keys in login fields.
    -- Scrolls over all known logins for this site
    if tbl.key == 'Up' or tbl.key == 'Down' then
        local input = tbl.target
        local txt = input.value
        local i = 0
        local candidates = clone(_page_credentials[page][1])
        local _start = _eval_js_on_element(page, input, 'selectionStart')
        local _end = _eval_js_on_element(page, input, 'selectionEnd')
        if txt ~= "" then
            -- if we have input without selection then let's find index
            -- in array with password for this login
            i = find_login_index(candidates, txt)
            -- if we have input field with some selection then let's
            -- find candidates that starts from manually entered text
            if _start ~= _end then
                local manual = string.sub(txt, 1, _start)
                candidates = filter(candidates, function(_, p) return string.find(p.login, manual) == 1 end)
            end
        end
        -- it may be nil when we have something in input fields
        -- but this value not in our list of candidates
        if i ~= nil then
            i = i + (tbl.key == 'Down' and 1 or -1);
            if i <= 0 then i = #candidates end
            if i > #candidates then i = 1 end
            input.value = candidates[i].login
            if _start ~= _end and _end == #txt then
                _end = #input.value
            end
            _input_select_range(page, input, _start, _end, 'backward')
        end
    end
end

local function _find_password_fields(form)
    local password_fields = form:query("input")
    password_fields = filter(password_fields, function(_, input)
        return string.match(input.type, "password") or input.attr.revealed_password
    end)
    return password_fields
end

local function _fill_password_fields(form, passwd)
    if not passwd then return end
    local password_fields = _find_password_fields(form)
    -- fill every password field with specified password
    for _, p in ipairs(password_fields) do
        p.value = passwd
    end
end

local function _load_passhash(page, form, input)
    local div = page.document.body:query("div#passhash-generator")
    if #div == 0 then
        -- load div template
        local f, _ = io.open(_plugin_location.."/passhash/passhash.html")
        local passhash_ui = f:read('*a')
        f:close()

        -- load style
        f, _ = io.open(_plugin_location.."/passhash/modal.css")
        local modal_css = f:read('*a')
        f:close()

        -- load js code
        f, _ = io.open(_plugin_location.."/passhash/passhash.js")
        local passhash_js = f:read('*a')
        f:close()

        -- now let's inject our div to page
        local _div = page.document:create_element('div', {id = 'passhash-generator', class = 'passhash-popup'})
        _div.inner_html= passhash_ui

        local _style = page.document:create_element('style', {})
        _style.inner_html= modal_css

        local _js = page.document:create_element('script', {language = 'JavaScript', type="text/javascript" })
        _js.inner_html= passhash_js

        page.document.body:append(_style)
        page.document.body:append(_js)
        page.document.body:append(_div)

        -- attach callbacs
        div = page.document.body:query("div#passhash-generator")[1]

        local close_cb = function()
            _eval_js_on_element(page, div, "style.display='none'")
            _eval_js_on_element(page, input, 'focus()')
        end

        local close = div:query("#passhash-close")[1]
        close:add_event_listener('click', false, close_cb)

        local submit_cb = function()
            local passwd = div:query("#hash-word")[1].value
            if passwd ~= '' then
                _fill_password_fields(form, passwd)
            end
            close_cb()
        end

        local submit = div:query("#passhash-ok")[1]
        submit:add_event_listener('click', false, submit_cb)

        local master_key = div:query("#master-key")[1]
        master_key:add_event_listener('keydown', false, function(_, tbl)
            if tbl.key == 'Enter' then
                submit_cb()
                tbl.cancel = true
                tbl.prevent_default = true
            end
        end)
    end
end

local function _passwd_field_keydown_cb(page, form, tbl)
    if tbl.alt_key then
        local input = tbl.target
        -- generate new password (alt-g)
        if tbl.key == 'U+0047' then
            _load_passhash(page, form, input)

            local div = page.document.body:query("div#passhash-generator")[1]
            _eval_js_on_element(page, div, "style.display='block'")

            local site_tag = div:query("#site-tag")[1]
            if site_tag then
                site_tag.value = _page_credentials[page][2]
            end

            local master_key = div:query("#master-key")[1]
            _eval_js_on_element(page, master_key, 'focus()')

        end
        -- show/hide password (alt-s)
        if tbl.key == 'U+0053' then
            input.attr.type = (input.attr.type == 'text' and 'password') or 'text';
            input.attr.revealed_password = 'true';
        end
    end
end

local function _input_field_focusin_cb(page, tbl)
    local input = tbl.target
    local login = input.value

    -- on focusIn populate login if no yet any text in field
    if _page_credentials[page][1][1] and login == '' then
        local first_login = _page_credentials[page][1][1].login
        input.value = first_login
        _input_select_range(page, input, #first_login, 0)
    else
        -- otherwise preserve selection in login field
        local _start = _eval_js_on_element(page, input, 'selectionStart')
        local _end = _eval_js_on_element(page, input, 'selectionEnd')
        _input_select_range(page, input, _end, _start)
    end
end

local function _input_field_focusout_cb(page, form, tbl)
    local input = tbl.target
    local login = input.value

    -- on focusOut find matching password and fill passwd fields with it
    if login then
        local p = find_login(_page_credentials[page][1], login)
        if p then
            local passwd = p.password
            _fill_password_fields(form, passwd)
        end
    end
end

local function call_pass_and_wait(signal, page_id, ...)
    -- creating lock file and waiting while it will be removed
    local lock_file = os.tmpname()
    io.open(lock_file):close()

    ui:emit_signal(signal, page_id, lock_file, ...)

    -- waiting for removal of lock file. ugly but works
    repeat
        local attr = lfs.attributes(lock_file)
        if attr then
            -- sleep one second
            os.execute("sleep " .. 1)
        else
            break
        end
    until false;
end

-- during submitting check login/password pair and if:
-- 1) login different -- request creation of new pass record
-- 2) pass changed for existing login -- request updating of pass record
-- 3) login and/or password are empty -- skip updation/creation of pass records
local function _form_submit_cb(page, form, login_field)
    local login = login_field.value
    local password

    -- let's check that all password fields contains same password
    local password_fields = _find_password_fields(form)
    local entered_passwords = {}
    for _, p in ipairs(password_fields) do
        entered_passwords[p.value] = true
    end
    entered_passwords = keys(entered_passwords)
    if #entered_passwords == 1 then
        password = entered_passwords[1]
        if password == '' then
            msg.error("Empty password entered in form. Ignoring.")
            return
        end
    else
        msg.error("Several different passwords entered in form. Ignoring.")
        return
    end

    if login then
        local domain = uri_to_domain(page.uri)
        local p = find_login(_page_credentials[page][1], login)
        if p and p.password then
            if p.password ~= password then
                -- we have login and different password. let's update pass record
                call_pass_and_wait("update-pass-for-login", page.id, domain, login, password, p.file)
            end
        else
            -- no such login yet, let's create new one
            call_pass_and_wait("create-pass-for-login", page.id, domain, login, password)
        end
    end
end

local function _process_one_form(page, form)
    if not _page_credentials[page] or _page_forms[page][form] then return end
    local inputs = form:query("input")
    -- filter out non text fields
    -- input type email used by some sites so we will catch it as well
    inputs = filter(inputs, function(_, input)
        return input.attr.type == 'text' or input.attr.type == 'email'
    end)
    -- filter input fields with id or name containing 'login', 'user' or 'identifier'
    inputs = filter(inputs, function(_, input)
        local id = string.lower(input.attr.id or '')
        local name = string.lower(input.attr.name or '')
        return string.match(name, "login") or
            string.match(name, "identifier") or
            string.match(name, "user") or
            string.match(id, "login") or
            string.match(id, "identifier") or
            string.match(id, "user")
    end)
    -- attach signals only if we have form with login field
    if #inputs >= 1 then
        if #inputs > 1 then
            msg.info("Several login fields in one form "..tostring(form).." detected. Will use only first one.")
        end
        local login = inputs[1]

        login:add_event_listener('input', false, function(_, tbl) _input_field_input_cb(page, tbl) end)
        login:add_event_listener('focusin', false, function(_, tbl) _input_field_focusin_cb(page, tbl) end)
        login:add_event_listener('focusout', false, function(_, tbl) _input_field_focusout_cb(page, form, tbl) end)
        login:add_event_listener('keydown', false, function(_, tbl) _input_field_keydown_cb(page, tbl) end)

        -- attach to every password field handler that will be responsible for generation passwords
        local password_fields = form:query("input")
        password_fields = filter(password_fields, function(_, input)
            return string.match(input.type, "password")
        end)

        for _, p in ipairs(password_fields) do
            p:add_event_listener('keydown', false, function(_, tbl) _passwd_field_keydown_cb(page, form, tbl) end)
        end

        -- attach to form submit signal
        form:add_event_listener('submit', false, function(_) _form_submit_cb(page, form, login) end)

        -- prefill login/password fields with first known login/password
        -- if we have something already in login field then try to find corresponding password for it
        -- such prefilled forms used by google for example
        local cred = _page_credentials[page][1][1]
        if login.value and login.value ~= "" then
            cred = find_login(_page_credentials[page][1], login.value)
        end
        if cred and cred.password then
            login.value = cred.login
            _fill_password_fields(form, cred.password)
        end
    end
    if not _page_forms[page] then
        _page_forms[page] = setmetatable({}, { __mode = "k" })
    end
    _page_forms[page][form] = true
end

local function _process_forms(page, forms)
    if #forms then
        for _, f in ipairs(forms) do
            _process_one_form(page, f)
        end
    end
end

local function _look_for_forms (page, frame)
    local forms= {}
    if page.document.body then
        if frame and frame.document.body then
            forms = frame.document.body:query('form') or {}
        else
            forms = page.document.body:query('form') or {}
        end
        -- passwd forms filtering
        forms = filter(forms, function(_, form)
            local passwords = filter(form:query("input"), function(_, input)
                return hasitem({"password"}, input.type)
            end)
            return #passwords > 0
        end)
        -- in addtion let's check iframes content if they exists
        local frames = {}
        if frame then
            frames = frame.document.body and frame.document.body:query('frame, iframe') or {}
        else
            frames = page.document.body:query('frame, iframe') or {}
        end
        for _, f in ipairs(frames) do
            local iframe_forms = _look_for_forms(page, f)
            if #iframe_forms > 0 then
                forms = join(forms, iframe_forms)
            end
        end
    end
    return forms
end

local function _capture_forms(page)
    local captured = _look_for_forms(page)
    if #captured > 0 then
        -- attach callbacks for new forms
        local new = {}
        for _, f in ipairs(captured) do
            if not _page_forms[page][f] then
                new[#new+1] = f
            end
        end
        if #new > 0 then
            -- if no yet info about credentials for page -- skip form processing
            -- forms will be processed later after receiving signal with credentials
            if _page_credentials[page] then
                _process_forms(page, new)
            end
        end
    end
end

ui:add_signal('get-plugin-configuration-reply', function(_, _, location)
    _plugin_location = location
end)

ui:add_signal('get-credentials-for-uri-reply', function(_, page, reply)
    _page_credentials[page] = reply
    _capture_forms(page)
end)

luakit.add_signal("page-created", function(page)
    if not _plugin_location then ui:emit_signal("get-plugin-configuration", page.id) end
    page:add_signal("document-loaded", function(_page)
        if not _page then return end
        _page_credentials[_page] = nil
        _page_forms[_page] = setmetatable({}, { __mode = "k" })

        local domain = uri_to_domain(_page.uri)
        if domain then
            ui:emit_signal("get-credentials-for-uri", _page.id, domain)

            if _page.document.body then
                -- and catch dom tree modification for refreshing for info
                -- if some form will be added at runtime or iframe will be loaded
                _page.document.body:add_event_listener("DOMSubtreeModified", false, function (_) return _capture_forms(_page) end)
            end
        end
    end)
end)

-- vim: et:sw=4:ts=8:sts=4:tw=80
