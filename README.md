luakit-plugins
==============

Version control for various [luakit](https://github.com/mason-larobina/luakit/) plugins.

Plugins list
============

* luakit-adblock
* tabmenu
* user agent switcher

Installing
==========

* In your GitHub application or any other graphical GIT client you may use you should clone this repository into your local luakit config directory, which may be like "/home/username/.config/luakit/".
By default, it will be named "luakit-plugins", so clone instead into "/home/username/.config/luakit/plugins" to let Lua find modules correctly.

* Using terminal git application is easier: ```git clone https://github.com/mason-larobina/luakit-plugins/ ~/.config/luakit/plugins```.


If you have no "rc.lua" in "~/.config/luakit/", then it takes no effect, so copy one from "/etc/xdg/luakit/" and find there text like "-- Optional user script loading --". Let us place 'require("plugins")' after that text, so plugins will be loaded.

Configuring
===========

By default, "plugins" will create "plugins/rc.lua" to enable factory default set of plugins each time there's no such file. You may adjust it as you wish or delete to revert to the default one.
