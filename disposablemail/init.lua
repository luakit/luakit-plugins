--- Disposablemail.
--
-- This module allows you to generate disposable mail box.
-- Idea and partial implementation taken from 'Bloody Vikings' FF plugin
--
-- # Capabilities
--
-- # Usage
--
-- * Press right mouse button in email field and select prefered disposable mail provider
-- * tab with disposable mailbox will be opened and input field will be filled with
--   generated email address
--
-- # Troubleshooting
--
-- # Files and Directories
--
-- @module disposablemail
-- @author Serg Kozhemyakin <serg.kozhemyakin@gmail.com>
-- @copyright 2018 Serg Kozhemyakin <serg.kozhemyakin@gmail.com>

local webview = require("webview")
local wm = require_web_module('plugins/disposablemail/disposablemail_wm')

local _inputs = {}

math.randomseed(os.time())

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

local function _gen_username()
    return random_string(6, '%a%d')..'.'..random_string(8, '%a%d')
end

-- function opens new tab for specified uri and executes
-- email extractor after finishing loading page
-- extractor must call passed to it callback function with one
-- parameter -- extracted email address

local function _open_disposable_mailbox(view, uri, extractor, opts)
    local w = webview.window(view)
    local disp_view = w:new_tab(uri, {switch = false})
    if type(extractor) == 'function' then
        local load_function
        load_function = function(_v, status)
            if status == 'finished' then
                extractor(_v, function(email)
                    if email and email ~= '' then
                        wm:emit_signal(view.id, 'oncontext-disposable-mail-field-reply', _inputs[view.id], email)
                        disp_view:remove_signal("load-status", load_function)
                        _inputs[view.id] = nil
                    end
                end, opts)
            end
        end
        disp_view:add_signal("load-status", load_function)
    elseif type(extractor) == 'string' then
        wm:emit_signal(view.id, 'oncontext-disposable-mail-field-reply', _inputs[view.id], extractor)
        _inputs[view.id] = nil
    end
end

-- 10minutemail.com

local function _10minutemail_extract(view, callb)
    view:eval_js("var l = document.getElementById('mailAddress'); (l?l.value:'')",
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
            end
        end})
end

local function _10minutemail(v)
    local submenu = {}
    table.insert(submenu, { "10minutemail.com", function (_)
        _open_disposable_mailbox(v, 'https://10minutemail.com/10MinuteMail/index.html', _10minutemail_extract)
    end})
    return submenu
end

-- anonbox.net

local function _anonbox_extract(view, callb)
    view:eval_js("var l = document.getElementsByTagName('dd'); (l[1]?l[1].firstChild.innerText:'')",
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
                view:eval_js("var l = document.getElementsByTagName('dd'); (l[3]?l[3].firstChild.getElementsByTagName('a')[0].getAttribute('href'):'')",
                    {callback = function(uri, e)
                        assert(uri, e)
                        if uri then view.uri = uri end
                    end})
            end
        end})
end

local function _anonbox(v)
    local submenu = {}
    table.insert(submenu, { "anonbox.net", function (_)
        _open_disposable_mailbox(v, 'https://anonbox.net/en', _anonbox_extract)
    end})
    return submenu
end

-- dispostable.com

local function _dispostable(v)
    local submenu = {}
    table.insert(submenu, { "dispostable.com", function (_)
        local u = _gen_username()
        _open_disposable_mailbox(v, 'http://www.dispostable.com/inbox/'..u..'/', u..'@dispostable.com')
    end})
    return submenu
end

-- dropmail.me

local function _dropmail_extract(view, callb)
    view:eval_js("var l = document.getElementsByClassName('email')[0]; (l?l.textContent.trim():'')",
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
            end
        end})
end

local function _dropmail(v)
    local submenu = {}
    table.insert(submenu, { "dropmail.me", function (_)
        _open_disposable_mailbox(v, 'https://dropmail.me/en/', _dropmail_extract)
    end})
    return submenu
end

-- fakemailgenerator.com

local function _fakemailgenerator_extract(view, callb)
    view:eval_js("var l = document.getElementById('home-email'); (l?l.value+document.getElementById('domain').textContent.trim():'')",
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
            end
        end})
end

local function _fakemailgenerator(v)
    local submenu = {}
    table.insert(submenu, { "fakemailgenerator.com", function (_)
        _open_disposable_mailbox(v, 'http://www.fakemailgenerator.com/', _fakemailgenerator_extract)
    end})
    return submenu
end

-- getairmail.com

local function _getairmail_extract(view, callb)
    view:eval_js("var l = document.getElementById('tempemail'); (l?l.value:'')",
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                msg.info(ret)
                callb(ret);
            end
        end})
end

local function _getairmail(v)
    local submenu = {}
    table.insert(submenu, { "getairmail.com", function (_)
        _open_disposable_mailbox(v, 'http://en.getairmail.com/random/', _getairmail_extract)
    end})
    return submenu
end

-- mailcatch.com

local function _mailcatch(v)
    local submenu = {}
    table.insert(submenu, { "mailcatch.com", function (_)
        local u = _gen_username()
        _open_disposable_mailbox(v, 'http://mailcatch.com/en/temporary-inbox?box='..u, u..'@mailcatch.com')
    end})
    return submenu
end

-- mailforspam.com

local function _mailforspam(v)
    local submenu = {}
    table.insert(submenu, { "mailforspam.com", function (_)
        local u = _gen_username()
        _open_disposable_mailbox(v, 'http://www.mailforspam.com/mail/'..u, u..'@mailforspam.com')
    end})
    return submenu
end

-- mailinator.com

local function _mailinator(v)
    local submenu = {}
    table.insert(submenu, { "mailinator.com", function (_)
        local u = _gen_username()
        _open_disposable_mailbox(v, 'https://www.mailinator.com/v2/inbox.jsp?zone=public&query='..u, u..'@mailinator.com')
    end})
    return submenu
end

-- mytemp.email

local function _mytemp_extract(view, callb)
    view:eval_js("var l = document.getElementsByClassName('menu-emails')[0].getElementsByTagName('md-list-item')[0].firstChild.firstChild.firstChild; (l?l.textContent.trim():'')",
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
            end
        end})
end

local function _mytemp(v)
    local submenu = {}
    table.insert(submenu, { "mytemp.email", function (_)
        _open_disposable_mailbox(v, 'https://mytemp.email/2/', _mytemp_extract)
    end})
    return submenu
end

-- temp-mail.org

local function _tempmail_extract(view, callb)
    view:eval_js("var l = document.getElementById('mail'); (l?l.value:'')",
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
            end
        end})
end

local function _tempmail(v)
    local submenu = {}
    table.insert(submenu, { "temp-mail.org", function (_)
        _open_disposable_mailbox(v, 'https://temp-mail.org/', _tempmail_extract)
    end})
    return submenu
end

-- tempr.email

local function _tempr_extract(view, callb, user)
    local js = [=[
let aliasNode = document.getElementById("LoginLocalPart");
aliasNode.value = '%{user}';
let domainNode = document.getElementById("LoginDomainId");
let domains = [];
for (let i = 0; i < domainNode.options.length; i++) {
  let option = domainNode.options[i];
  if (!option.disabled && option.className != "disabled") {
    domains.push(option.value);
  }
}
domainNode.value = domains[Math.floor(Math.random() * domains.length)];
let domain = domainNode.options[domainNode.selectedIndex].text.trim().split(" ")[0];
document.getElementsByName("LoginButton")[0].click();
'%{user}' + "@" + domain;
]=];
    js = string.gsub(js, '%%{user}', user)
    view:eval_js(js,
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
            end
        end})
end

local function _tempr(v)
    local submenu = {}
    table.insert(submenu, { "tempr.email", function (_)
        local u = _gen_username()
        _open_disposable_mailbox(v, 'https://tempr.email/en/', _tempr_extract, u)
    end})
    return submenu
end

-- trash-mail.com

local function _trashmail_extract(view, callb, user)
    local js = [=[
try {
  let aliasNode = document.getElementById("inputEmail");
  aliasNode.value = '%{user}';
  let domainNode = document.getElementById("form-domain-id");
  let domains = new Array();
  for (let i = 0; i < domainNode.options.length; i++) {
    let option = domainNode.options[i];
    if (option.value.charAt(option.value.length - 1) === "0") {
      domains.push(option.value);
    }
  }
  domainNode.value = domains[Math.floor(Math.random() * domains.length)];
  let domain = domainNode.options[domainNode.selectedIndex].text.trim().split(" ")[0];
  document.forms["inbox-form"].submit();
  '%{user}' + "@" + domain;
} catch(e) {
  let addressNode = document.getElementById("heading2");
  addressNode.textContent.split("#")[1].trim();
}
]=];
    js = string.gsub(js, '%%{user}', user)
    view:eval_js(js,
        {callback = function (ret, err)
            assert(ret, err)
            if ret and ret ~= '' then
                callb(ret);
            end
        end})
end

local function _trashmail(v)
    local submenu = {}
    table.insert(submenu, { "trash-mail.com", function (_)
        local u = _gen_username()
        _open_disposable_mailbox(v, 'https://www.trash-mail.com/inbox/', _trashmail_extract, u)
    end})
    return submenu
end

-- yopmail.com

local _known_yopmail_domains = {'@yopmail.com',
    '@yopmail.fr',
    '@yopmail.net',
    '@jetable.fr.nf',
    '@nospam.ze.tc',
    '@nomail.xl.cx',
    '@mega.zik.dj',
    '@speed.1s.fr',
    '@cool.fr.nf',
    '@courriel.fr.nf',
    '@moncourrier.fr.nf',
    '@monemail.fr.nf',
    '@monmail.fr.nf',}

local function _yopmail(v)
    local submenu = {}
    for _,domain in ipairs(_known_yopmail_domains) do
        table.insert(submenu, { domain, function (_)
            local u = _gen_username()
            _open_disposable_mailbox(v, 'http://yopmail.com/en/?'..u, u..domain)
        end})
    end
    return submenu
end

-- combining all together

local _disposable_providers = {
    { title = '10minutemail.com', s = _10minutemail},
    { title = 'annonbox.net', s = _anonbox},
    { title = 'dispostable.com', s = _dispostable},
    { title = 'dropmail.me', s = _dropmail},
    { title = 'fakemailgenerator.com', s = _fakemailgenerator},
    { title = 'getairmail.com', s = _getairmail},
    { title = 'mailcatch.com', s = _mailcatch},
    { title = 'mailforspam.com', s = _mailforspam},
    { title = 'mailinator.com', s = _mailinator},
    { title = 'mytemp.email', s = _mytemp},
    { title = 'temp-mail.org', s = _tempmail},
    { title = 'tempr.email', s = _tempr},
    { title = 'trash-mail.com', s = _trashmail},
    { title = 'yopmail.com', s = _yopmail },
}

local function populate_disposable_menu(w, menu)
    if _inputs[w.id] then
        local submenu = {}
        for _,v in ipairs(_disposable_providers) do
            local sub = v.s(w)
            if sub then
                if #sub == 1 then
                    table.insert(submenu, sub[1])
                else
                    table.insert(submenu, {v.title, sub})
                end
            end
        end
        table.insert(menu, true)
        table.insert(menu, { "Choose disposable email", submenu })
    end
end

wm:add_signal('oncontext-disposable-mail-field', function (_, page, id)
    _inputs[page] = id
end)

webview.add_signal("init", function (w)
    w:add_signal("populate-popup", populate_disposable_menu )
end)

-- vim: et:sw=4:ts=8:sts=4:tw=80
