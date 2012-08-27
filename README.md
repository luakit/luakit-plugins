luakit-plugins
==============

Version control for various [luakit](https://github.com/mason-larobina/luakit/) plugins.

Plugins list
============

* AdBlock from [luakit-adblock](https://github.com/Plaque-fcc/luakit-adblock/)
* oldschoolkeys (some old good keybindings from luakit stable releases up to March 2012)
* tabmenu (menu of tabs open)
* user agent switcher (allow Luakit to fake it's an other browser)
* yank selection (simply yanks selection like yanking title or URI)

Installing
==========

* In your GitHub application or any other graphical GIT client you may use you should clone this repository into your local luakit config directory, which may be like "/home/username/.config/luakit/".
By default, it will be named "luakit-plugins", so clone instead into "/home/username/.config/luakit/plugins" to let Lua find modules correctly.

* Using terminal git application is easier: ```git clone https://github.com/mason-larobina/luakit-plugins/ ~/.config/luakit/plugins```.


If you have no "rc.lua" in "~/.config/luakit/", then it takes no effect, so copy one from "/etc/xdg/luakit/" and find there text like "-- Optional user script loading --". Let us place 'require("plugins")' after that text, so plugins will be loaded.

Configuring
===========

By default, "plugins" will create "plugins/rc.lua" to enable factory default set of plugins each time there's no such file. You may adjust it as you wish or delete to revert to the default one. 
Since v0.1.0 'rc.lua' can contain
```lua
plugins.policy = "automatic"
```
This will enable plugins module to load everything ignoring other implicit selections; to change this behaviour, set this value to "manual".

Development guidelines
======================

You are encouraged to compose your own extensions and propose adding them to this repository. Even if your (or written by someone else but found by you across the WWW) extension can provide rather specialized functions useful for quite-not-most-of-websurfers… Well, you know, not most of websurfers prefer a lightweight Luakit, correct? Feel free to use any of the plugins or avoid any of them. 
So, the basis is:

* The extension **should not be destructive**! This means, it's not allowed to conflict with the basis of Luakit itself or harm other extensions.
* The extension comes first into 'candidates' branch, so checkout 'candidates' first if you fork this repo and wish your changes be pulled easily.
* The main module should have the same name (prefixed with 'plugins.') the extension directory has and be placed in 'init.lua' file under the directory.
* If you provide other (auxiliary) parts in Lua along with the main module, each part should have the same name the main module has (suffixed by the '.' and the part name), be located in the same directory and the file should be named with part name suffixed with '.lua'. For each auxiliary part of the extension, there should be an entry in 'companions' file containing its name.
* If you provide non-Lua (bash, etc.) scripts, their names should begin with the name of the extension that they are intended to aid and shortly describe their action. Should generally be placed in 'tools/'.
* Finally, yes, if it's too hard for you to follow these directions because of anything (you may be not acquainted to Luakit and/or Lua itself), the extension you wish us to add still can be added. All we need is to know where we should get it from if it's been licensed under GPLv2+-alike license OR if you can imagine things that are interesting but you "did not meet them in the wild" yet, welcome to the bugtracker and describe what you want from Luakit: https://github.com/mason-larobina/luakit-plugins/issues 
Please, don't forget to say it's a _feature request_, not a _bug report_!
