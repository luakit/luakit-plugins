--- disposablemail web module.
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
-- @module disposablemail.disposablemail_wm
-- @author Serg Kozhemyakin <serg.kozhemyakin@gmail.com>
-- @copyright 2018 Serg Kozhemyakin <serg.kozhemyakin@gmail.com>

local ui = ipc_channel('plugins/disposablemail/disposablemail_wm')
local luakit = require('luakit')
local lousy = require("lousy")
local filter = lousy.util.table.filter_array

local _fields = setmetatable({}, { __mode = "v" })
local _inputs = setmetatable({}, { __mode = "k" })

ui:add_signal('oncontext-disposable-mail-field-reply', function(_, _, target_id, generated_email)
    local target = _fields[target_id]
    if target then
        target.value = generated_email
        _fields[target_id] = nil
    end
end)

local function _oncontextmenu(page, element, event)
    local target = event.target
    if (target.attr.type == 'text' or target.attr.type == 'email') then
        local id = target.attr.id
        if not id or id == '' then
            local tmp = tostring(target)
            local addr = string.match(tmp, ": (.+)$")
            id = '_'..target.attr.type..'_'..addr
        end
        _fields[id] = target
        ui:emit_signal("oncontext-disposable-mail-field", page.id, id)
    else
        ui:emit_signal("oncontext-disposable-mail-field", page.id, nil)
    end
end

local function _capture_inputs(page, document)
    if document then
        local inputs = document:query('input')
        inputs = filter(inputs, function(_, input)
            return input.attr.type == 'text' or input.attr.type == 'email'
        end)
        for _, i in ipairs(inputs) do
            if not _inputs[i] then
                i:add_event_listener("contextmenu", false, function (element, event) _oncontextmenu(page, element, event) end)
                _inputs[i] = true
            end
        end
    end
end

local function _capture_frames(page)
    local frames = page.document.body:query('frame, iframe')
    if frames and #frames > 0 then
        for _, f in ipairs(frames) do
            _capture_inputs(page, f.document.body)
        end
    end
end

luakit.add_signal("page-created", function(page)
    page:add_signal("document-loaded", function(_page)
        if not _page.document.body then return end
        _inputs = {}
        _page.document.body:add_event_listener("DOMSubtreeModified", false, function (_) _capture_frames(_page) end)
        _capture_inputs(page, _page.document.body)
        _capture_frames(_page)
    end)
end)

-- vim: et:sw=4:ts=8:sts=4:tw=80
