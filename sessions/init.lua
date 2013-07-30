--- -*- mode: Lua; tab-width: 2; indent-tabs-mode:nil; -*-         ---
----------------------------------------------------------------------
--- Authors: Andre Hilsendeger < Andre.Hilsendeger@gmail.com >     ---
--- Created: 2013-07-30                                            ---
--- Last-Updated: 2013-07-30                                       ---
---   By: Andre Hilsendeger < Andre.Hilsendeger@gmail.com >        ---
---                                                                ---
--- Filename: sessions/init                                        ---
--- Description:                                                   ---
--- Based on 'luakit/lib/session.lua'                              ---
--- Session saving / loading functions                             ---
--- Extends the original by allowing multiple named sessions and   ---
--- a sessionlist.                                                 ---
----------------------------------------------------------------------

-- Get lua environment
----------------------------------------------------------------------
local os           = os
local pcall        = pcall
local pairs        = pairs
local ipairs       = ipairs
local string       = string
local setmetatable = setmetatable
local table        = table
local lfs          = require "lfs"

-- get luakit environment
----------------------------------------------------------------------
local luakit    = luakit
local globals   = globals
local window    = window
local session   = require "session" and session
local lousy     = require "lousy"
local buf       = lousy.bind.buf
local cmd       = lousy.bind.cmd
local key       = lousy.bind.key
local new_mode  = new_mode
local add_cmds  = add_cmds
local add_binds = add_binds

-- plugins environment
----------------------------------------------------------------------
local plugins = plugins

module "plugins.sessions"

-- Module variables
----------------------------------------------------------------------

-- Store completion state (indexed by window)
local data = setmetatable({}, { __mode = "k" })
plugins.sessions = plugins.sessions or {}
sessions         = plugins.sessions
sessions.list    = {}

-- Module options
sessions.dir     = sessions.dir or luakit.data_dir .. "/sessions"
if sessions.mode_notification == nil then
   sessions.mode_notification = [[Use j/k to move, [d]elete,
 [r]estore,       [R]estore & delete,
 [t]ab restore,   [T]ab restore & delete.]]
end

-- Sessions API
----------------------------------------------------------------------

-- Create api function. (Wraps original session functions)
local function create_sessions_api_fun(spec)
   sessions[spec.name] = function(name, ...)
      if not data[name] then
         if spec.create then sessions.create(name)
         else return end
      end
      --      local session = data[name]
      local old_file = session.file
      session.file = data[name]
      pcall(function(...) session[spec.name](...) end, ...)
      session.file = old_file
   end
end

local function create_sessions_api(specs)
   for _,spec in ipairs(specs) do
      create_sessions_api_fun(spec)
   end
end

create_sessions_api(
   {
      { name = 'save', create = true,
        "save(name, wins): Saves session to 'name' in 'sessions.dir'."},
      { name = 'load',
        "load(name, delete): Load window and tab state from session file"},
      { name = 'restore',
        [[restore(name, delete): Spawn windows from saved session and
          return the last window]] },
      { name = 'tab_restore',
        "tab_restore(name, w, delete): Create tabs from saved session in w" },
   })

-- Extend session with new function 'tab_restore'
session.tab_restore = function(w, delete)
   wins = session.load(delete)
   if not wins then return end
   for _, win in ipairs(wins) do
      for _, tab in ipairs(win) do
         w:new_tab(tab.uri, tab.current)
      end
   end
end

-- Sessions list API
----------------------------------------------------------------------

function sessions.list.delete(w)
   local row = w.menu:get()
   if not row then return end
   os.remove(row.file)
   data[row.name] = nil
   w.menu:del()
end

-- Restore a session into a new window
function sessions.list.restore(w)
   local row = w.menu:get()
   if not row then return end
   sessions.restore(row.name, false)
end

function sessions.list.restore_delete(w)
   sessions.list.restore(w)
   sessions.list.delete(w)
end

-- Restore a session into current window with tabs
function sessions.list.tab_restore(w)
   local row = w.menu:get()
   if not row then return end
   sessions.tab_restore(row.name, w, false)
end

function sessions.list.tab_restore_delete(w)
   sessions.list.tab_restore(w)
   sessions.list.delete(w)
end

-- Get existing sessions
----------------------------------------------------------------------

-- Create a new 'session' and store in 'data'.
function sessions.create(name)
   data[name] = string.format('%s/%s', sessions.dir, name)
end

-- Create an entry in 'data' for each file in 'dir'.
function sessions.init(dir)
   lfs.mkdir(dir)
   for file in lfs.dir(dir) do
      if lfs.attributes(dir .. '/' .. file, 'mode') == 'file' then
         sessions.create(file)
      end
   end
end

-- Add methods to window
----------------------------------------------------------------------

-- Start sessionslist mode
window.methods.sessionslist = function(w)
   w:set_mode('sessionslist')
end

-- Save current window to a session file
window.methods.session_save_current = function(w, name)
   name = name or 'unknown'
   sessions.save(name, {w,})
end

-- Save all windows to a session file
window.methods.session_save_all_windows = function(w, name)
   name = name or 'unknown'
   sessions.save(name, lousy.util.table.values(window.bywidget))
end

-- Create sessionlist mode
----------------------------------------------------------------------
local function mode_enter(w)
   local rows = {}
   for name, file in pairs(data) do
      table.insert(rows, {name, name = name, file = file })
   end
   w.menu:build(rows)
   w.menu:show()
   w:notify(sessions.mode_notification, false)
end

local function mode_leave(w)
   w.menu:hide()
end

new_mode(
   "sessionslist",
   {
      enter = mode_enter,
      leave = mode_leave,
   })

-- Bindings
----------------------------------------------------------------------
add_binds('normal',
   {
      buf('^Zw$',
          "Save the current session (current window).",
          function(w) w:enter_cmd(':session-save-current-window ') end),
      buf('^ZW$',
          "Save the current session (all windows).",
          function(w) w:enter_cmd(':session-save-all-windows ') end),
      buf('^ZL$',
          "Open session list.",
          window.methods.sessionslist),
   })

add_cmds(
   {
      cmd('sessionslist',
          "Open session list.",
          window.methods.sessionslist),
      cmd('session-save-current-window',
          "Save the current session (current window).",
          window.methods.session_save_current),
      cmd('session-save-all-windows',
          "Save the current session (all window).",
          window.methods.session_save_all_windows),
   })

add_binds('sessionslist',
   {
      key({}, 'd',
          "Delete selected session.",
          sessions.list.delete),
      key({}, 'Return',
          "Restore selected session (don't delete).",
          sessions.list.restore),
      key({}, 'r',
          "Restore selected session (don't delete).",
          sessions.list.restore),
      key({}, 'R',
          "Restore and delete selected session.",
          sessions.list.restore_delete),
      key({}, 't',
          "Restore selected session in tabs (don't delete).",
          sessions.list.tab_restore),
      key({}, 'T',
          "Tab restore and delete selected session.",
          sessions.list.tab_restore_delete),
   })

----------------------------------------------------------------------
sessions.init(sessions.dir)
