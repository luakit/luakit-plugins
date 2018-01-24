--- Tab history module.
--
-- This module switching to previously active tab when active tab closed
--
-- # Capabilities
--
-- # Usage
--
-- * Add `require "tabhistory"` to your `config.rc`.
--
-- # Troubleshooting
--
-- # Files and Directories
--
--
-- @module tabhistory
-- @author Serg Kozhemyakin <serg.kozhemyakin@gmail.com>
-- @copyright 2017-2018 Serg Kozhemyakin <serg.kozhemyakin@gmail.com>

local window = require("window")

local _active_tab_stack = setmetatable({}, { __mode = "k" })

local function _count(tbl)
    local n = 0
    for _,_ in pairs(tbl) do
        n = n + 1
    end
    return n
end

-- called when tab removed
local function _page_removed_cb(nb, view)
    local w = assert(window.ancestor(nb))
    -- removing last element from stack because page switch was called already
    -- and last element in stack new tab that luakit activated
    table.remove(_active_tab_stack[w][nb])
    -- clean stack from removed view
    local tmp = _active_tab_stack[w][nb]
    local new = setmetatable({}, { __mode = "v" })
    for n = 1, #tmp do
        if tmp[n] ~= view then
            table.insert(new, tmp[n])
        end
    end
    _active_tab_stack[w][nb] = new
    -- if page stack contains more then one element then switch to previous in stack page
    if _count(_active_tab_stack[w][nb]) > 1 then
        local prev = table.remove(_active_tab_stack[w][nb])
        nb:switch(nb:indexof(prev))
    end
end

-- called when tab switched
local function _switch_page_cb(nb, view)
    local w = assert(window.ancestor(nb))
    table.insert(_active_tab_stack[w][nb], view)
end

local function _attach_signals_to_notebook(nb)
    local w = assert(window.ancestor(nb))
    _active_tab_stack[w][nb] = setmetatable({}, { __mode = "v" })
    nb:add_signal("page-removed", _page_removed_cb)
    nb:add_signal("switch-page", _switch_page_cb)
end

-- called when tabgroup added
local function _tg_page_added_cb(grp, nb)
    _attach_signals_to_notebook(nb)
end

-- called when tabgroup removed
local function _tg_page_removed_cb(grp, nb)
    nb:remove_signal("page-removed", _page_removed_cb)
    nb:remove_signal("switch-page", _switch_page_cb)
    -- no assert because of removing last tg during browser closing
    local w = window.ancestor(grp)
    if w then
        _active_tab_stack[w][nb] = nil
    end
end

local function _attach_signals_to_tabgroups(grp)
    grp:add_signal("page-added", _tg_page_added_cb)
    grp:add_signal("page-removed", _tg_page_removed_cb)
    -- add callbacks to all already created tabgroups
    for n = 1, grp:count() do
        _attach_signals_to_notebook(grp[n])
    end
end

window.add_signal("init", function (w)
    _active_tab_stack[w] = setmetatable({}, { __mode = "k" })
    if w.tabs.parent.type == "notebook" then
        _attach_signals_to_tabgroups(w.tabs.parent)
    else
        _attach_signals_to_notebook(w.tabs)
    end
end)

-- vim: et:sw=4:ts=8:sts=4:tw=80
