-------------------------------------------------------------------------------
--                                                                           --
-- Search mode: add to popup menu list of all configured search egines       --
--                                                                           --
-------------------------------------------------------------------------------

local lousy = require("lousy")
local table_keys = lousy.util.table.keys
local webview = require ("webview")
local window = require ("window")
local settings = require ("settings")
local luakit = require ("luakit")
local binds, modes = require("binds"), require("modes")
local add_binds, add_cmds = modes.add_binds, modes.add_cmds
local menu_binds = binds.menu_binds
local new_mode = require("modes").new_mode

local function try_search_engine (engine, selection)
    if type(engine) == "string" then
        return string.format(engine, luakit.uri_encode(selection))
    else
        local ok, ret = pcall(engine, selection)
        return ok and ret or nil
    end
end

local function populate_search_menu (view, menu)
    -- populate this menu only if we have something selected on page
    local selection = luakit.selection.primary
    if selection then
        local search_engines = settings.get_setting_for_view(view, "window.search_engines")
        if search_engines then
            -- let's populate search submenus
            local submenu = {}
            local n = 1
            for _, name in ipairs(table_keys(search_engines)) do
                local engine = search_engines[name]
                local url = try_search_engine(engine, selection)
                if url then
                    submenu[n] = {}
                    submenu[n][1] = name
                    submenu[n][2] = function (view)
                        view.uri = url
                        -- clean primary selection after search?
                        luakit.selection.primary = ""
                    end
                    n = n+1
                end
            end
            n = #menu + 1
            -- add separator
            menu[n] = true
            -- add submenu
            local text = selection
            if #text > 20 then
                text = string.sub(text, 1, 20) .. "..."
            end
            local item = string.format("Search '%s' in:", text)
            menu[n+1] = {}
            menu[n+1][1] = item
            menu[n+1][2] = submenu
        end
    end
end

webview.add_signal("init", function (view)
    view:add_signal("populate-popup", populate_search_menu)
end)

-- View search engines in list
new_mode("search-menu", {
    enter = function (w)
        local rows = {{ "Title", " URI", title = true }}
        local selection = luakit.selection.primary
        local search_engines = settings.get_setting_for_view(w.view, "window.search_engines")
        if search_engines then
            for _, name in ipairs(table_keys(search_engines)) do
                local engine = search_engines[name]
                local _title = lousy.util.escape(name)
                local _uri = try_search_engine(engine, selection)
                if _uri then
                    _uri = lousy.util.escape(_uri)
                    table.insert(rows, { "  " .. _title, " " .. _uri, uri = _uri })
                end
            end
            w.menu:build(rows)
            w:notify("Use j/k to move, t to open search results in new tab, w to open search results in new win.", false)
        end
    end,

    leave = function (w)
        w.menu:hide()
    end,
})

-- Add search menu binds
add_binds("search-menu", lousy.util.table.join({
    { "t", "Open search results in new tab", function (w)
        local row = w.menu:get()
        w:set_mode()
        if row and row.uri then
            -- clean primary selection after search?
            luakit.selection.primary = ""
            w:new_tab(row.uri)
        end
    end },

    { "w", "Open search results in new window", function (w)
        local row = w.menu:get()
        w:set_mode()
        if row and row.uri then
            -- clean primary selection after search?
            luakit.selection.primary = ""
            window.new({row.uri})
        end
    end },

    { "<Return>", "Open search results in current tab.", function (w)
        local row = w.menu:get()
        w:set_mode()
        if row and row.uri then
            -- clean primary selection after search?
            luakit.selection.primary = ""
            w.view.uri = row.uri
        end
    end },
}, menu_binds))

local function open_search_menu(w, _)
    local selection = luakit.selection.primary
    if not selection then
        w:notify("No text in primary selection")
    else
        w:set_mode("search-menu")
    end
end

add_binds("normal", {
    { "S", "Open search menu", open_search_menu, {count=1} },
})

-- Add `:search_menu` command to view all menu with search engines
add_cmds({
    { ":search-menu, :sm", "Select search engine from menu.", open_search_menu },
})

-- vim: et:sw=4:ts=8:sts=4:tw=80
