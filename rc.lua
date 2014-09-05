-- Standard awesome library

local awful = require("awful")
require("awful.autofocus")
awful.rules = require("awful.rules")
awful.tag = require("awful.tag")

local wibox = require("wibox")
local widget = require("wibox.widget")

-- Theme handling library

local beautiful = require("beautiful")
local gears = require("gears")

-- Notification library
local naughty = require("naughty")
naughty.config.presets.normal.icon_size = 32
naughty.config.presets.normal.icon = "/usr/share/icons/Amaranth/64x64/status/dialog-info.png"

-- Extra widgets

require("battery")
require("mail")
require("cpu")
require("mixer")
require("kbdlayout")
require("cal")

-- Debug

function debug_notification(message)
	naughty.notify({text = "Debug: ".. tostring(message)})
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(os.getenv("HOME") .. "/.awesome/themes/custom/theme.lua")
gears.wallpaper.centered(nil, nil)
if beautiful.wallpaper then
	for s = 1,screen.count() do
		gears.wallpaper.centered(beautiful.wallpaper, s)
	end
end

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor
script_pwd = os.getenv("HOME") .. "/.awesome/scripts/"

awe_exit = script_pwd .. "awe-exit"
awe_lock = script_pwd .. "awe-lock"
brightness_less = script_pwd .. "brightness_less"
brightness_more = script_pwd .. "brightness_more"
backlight_toggle = script_pwd .. "backlight_toggle"
wifi_toggle = script_pwd .. "wifi_toggle"
bt_toggle = script_pwd .. "bt_toggle"
fan_cycle = script_pwd .. "fan_cycle"
xclip_copy = script_pwd .. "xclip_copy"
xclip_paste = script_pwd .. "xclip_paste"

awful.util.spawn(script_pwd .. "startup")

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.top,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile,
    awful.layout.suit.max,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
--    awful.layout.suit.max.fullscreen --,
--    awful.layout.suit.magnifier
}

activescreen = 1;

-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
-- Rename to break old depending code
mytags = {}

function set_active_screen(i) 
	activescreen = i;

	-- make naughty notifications follow active screen
	naughty.config.defaults.screen = activescreen;
end

oldspawn = awful.util.spawn
awful.util.spawn = function (cmd, sn, screen)
	oldspawn(cmd, sn, screen or activescreen)
end

oldspawnws = awful.util.spawn_with_shell
awful.util.spawn = function (cmd, screen)
	oldspawnws(cmd, screen or activescreen)
end

tagall = {
	{name = "1",        layout = awful.layout.suit.tile, screen = 1 },
	{name = "2",        layout = awful.layout.suit.tile, screen = 1 },
	{name = "3",        layout = awful.layout.suit.tile, screen = 1 },
	{name = "4",        layout = awful.layout.suit.tile, screen = 1 },
	{name = "5: www",   layout = awful.layout.suit.tile, screen = 2 },
	{name = "6: mail",  layout = awful.layout.suit.tile, screen = 2 },
	{name = "7: im",    layout = awful.layout.suit.tile, screen = 2 },
	{name = "8: music", layout = awful.layout.suit.tile, screen = 2 },
	{name = "9: video", layout = awful.layout.suit.tile, screen = 2 },
	{name = "0",	    layout = awful.layout.suit.tile, screen = 2 },
}

for i, tset in ipairs(tagall) do
	local s = math.min(screen.count(), tset.screen);
	mytags[i] = awful.tag.add(tset.name, {
		screen = s, 
		layout = tset.layout})
	awful.tag.setproperty(mytags[i], "mwfact", 0.65);
end

mytags[1].selected = true;
if (screen.count() > 1) then
	mytags[5].selected = true
end

-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock.new(" %a %d %b, %H:%M ", 5)
-- Show calendar on hover
cal.register(mytextclock, "<span color=\"#00c000\"><b>%s</b></span>")

-- Create a systray
mysystray = widget.systray()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, 
						function (t)
							set_active_screen(awful.tag.getscreen(t))
							awful.tag.viewonly(t);
						end),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag)--,
--                    awful.button({ }, 4, awful.tag.viewnext),
--                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
					 awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end)
					)

-- Simple charge indicator
mychargeindicator = battery("BAT1")

-- Mail indicator
mymailindicator = mail(function (x) 
	return 
		(x == "tsybulinhome@gmail.com") or
		(x == "tsybulin@crec.mipt.ru") or
		(x == "uranix@parallels.mipt.ru")
end)

-- Cpu indicator
mycpuindicator = cpu()

-- Mixer indicator
activevolumecontrol = {device = 0, control = "Headphone"}

myvolumeindicator = mixer({
	{alias = "MID", control = "Headphone", name = "Head"},
	{alias = "MID", control = "Speaker", name = "Speak"},
	{alias = "Device", control = "PCM", name = "Usb"}
}, activevolumecontrol)

-- Layout indicator
mylayoutindicator = kbdlayout({on = "RU", off = "US"});

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () set_active_screen(s); awful.layout.inc(layouts, 1);  end),
                           awful.button({ }, 3, function () set_active_screen(s); awful.layout.inc(layouts, -1); end),
                           awful.button({ }, 4, function () set_active_screen(s); awful.layout.inc(layouts, 1);  end),
                           awful.button({ }, 5, function () set_active_screen(s); awful.layout.inc(layouts, -1); end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons);

	local left_widgets = wibox.layout.fixed.horizontal()
	left_widgets:add(mylayoutbox[s]);
	left_widgets:add(mytaglist[s]);
	left_widgets:add(mypromptbox[s]);

	local right_widgets = wibox.layout.fixed.horizontal()
    if s == 1 then right_widgets:add(mylayoutindicator) end
    if s == 1 then right_widgets:add(myvolumeindicator) end
    if s == 1 then right_widgets:add(mycpuindicator) end
    if s == 1 then right_widgets:add(mymailindicator) end
    if s == 1 then right_widgets:add(mychargeindicator) end
    if s == 1 then right_widgets:add(mysystray) end
    if s == 1 then right_widgets:add(mytextclock) end

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", height = 24, screen = s })

    -- Add widgets to the wibox - order matters
	local all_widgets = wibox.layout.align.horizontal()
	all_widgets:set_left(left_widgets)
	all_widgets:set_middle(mytasklist[s])
	all_widgets:set_right(right_widgets)

    mywibox[s]:set_widget(all_widgets)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
	awful.button({ }, 1, function()
		set_active_screen(mouse.screen)
	end) 
))
-- }}}

-- {{{ Global bindings
awful.tag.selectedlist = function(s)
    local s  = s or activescreen
    local tags = awful.tag.gettags(s)
    local vtags = {}
    for i, t in pairs(tags) do
        if t.selected then
            vtags[#vtags + 1] = t
        end
    end
    return vtags
end

globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",  awful.tag.viewprev),
    awful.key({ modkey,           }, "k",  awful.tag.viewnext),

    awful.key({ modkey,           }, "Left",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "Right",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "space", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Shift"   }, "r", function ()
		awful.util.pread("awesome -k 2> /tmp/awesome-config-check")
		local status = awful.util.pread("/bin/cat /tmp/awesome-config-check")
		local good = "\226\156\148 Configuration file syntax OK.\n";

		if (status ~= good) then
			status = status:sub(1, status:len() - 1)
			naughty.notify({ preset = naughty.config.presets.critical,
							 title = "Config file has errors!",
							 timeout = 5,
							 text = status })
		else
			awesome.restart()
		end
	end),
    awful.key({ modkey,           }, "q", function () awful.util.spawn(awe_lock) end),
    awful.key({ modkey, "Shift"   }, "e", function () awful.util.spawn(awe_exit) end),
    awful.key({					  }, "XF86PowerOff", function () awful.util.spawn(awe_exit) end),
	awful.key({ modkey,           }, "c", function () awful.util.spawn(xclip_copy) end),
	awful.key({ modkey,           }, "v", function () awful.util.spawn(xclip_paste) end),

	-- Layout managing
    awful.key({ modkey,           }, "l", function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h", function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "l", function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "h", function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "l", function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "h", function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "w", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey,           }, "r", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
	awful.key({ modkey },            "Return", 
			function () 
				mypromptbox[activescreen]:run() 
			end),

	awful.key({ modkey }, "x",
			function ()
				awful.prompt.run({ prompt = "Run Lua code: " },
					mypromptbox[activescreen].widget,
					awful.util.eval, nil,
					awful.util.getdir("cache") .. "/history_eval")
			end),
-- }}}

-- {{{ Misc bindings
	awful.key({}, "XF86Display", function()
			set_active_screen(1);
			awful.util.spawn(os.getenv("HOME") .. "/.awesome/scripts/randr");
		end),
	awful.key({}, "XF86AudioRaiseVolume", function()
			awful.util.spawn(string.format('amixer -D hw:%d -q set %s 5%%+', 
				activevolumecontrol.device, activevolumecontrol.control))
		end),
	awful.key({}, "XF86AudioLowerVolume", function()
			awful.util.spawn(string.format('amixer -D hw:%d -q set %s 5%%-', 
				activevolumecontrol.device, activevolumecontrol.control))
		end),
	awful.key({}, "XF86AudioMute", function()
			awful.util.spawn(string.format('amixer -D hw:%d -q sset %s toggle', 
			activevolumecontrol.device, activevolumecontrol.control))
		end),
	awful.key({}, "XF86MonBrightnessDown", function()
			awful.util.spawn(brightness_less)
		end),
	awful.key({}, "XF86MonBrightnessUp", function()
			awful.util.spawn(brightness_more)
		end),
	awful.key({}, "XF86Launch1", function()
			local status = awful.util.pread(backlight_toggle);
			naughty.notify({
				text = "Backlight status: " .. status, 
				title = "Backlight",
				icon = "/usr/share/icons/gnome/32x32/status/messagebox_info.png"
				})
			-- Toggle backlight
		end),
	awful.key({}, "XF86Launch2", function()
			local status = awful.util.pread(bt_toggle)
			naughty.notify({
				text = "Bluetooth status: " .. status,
				title = "Bluetooth",
				icon = "/usr/share/icons/oxygen/32x32/apps/preferences-system-bluetooth.png"
				})
			-- Toggle bluetooth
		end),
	awful.key({}, "XF86Launch3", function()
			local status = awful.util.pread(fan_cycle);
			naughty.notify({
				text = "Fan mode: " .. status, 
				title = "Fan",
				icon = "/usr/share/icons/oxygen/32x32/devices/cpu.png"
				})
			-- Cycle fan mode
		end),
	awful.key({}, "XF86WLAN", function()
			local status = awful.util.pread(wifi_toggle);
			naughty.notify({
				text = "WiFi status: " .. status, 
				title = "WiFi",
				icon = "/usr/share/icons/oxygen/32x32/devices/network-wireless.png"
				})
			-- Toggle wireless
		end)
)
-- }}}

-- {{{ Client bindings
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      
		function (c) 
			-- Cycle between Normal -> Maximized -> Fullscreen -> Normal
			local maxi = c.maximized_horizontal and c.maximized_vertical
			local full = c.fullscreen
			if not full and not maxi then
				-- Normal
				c.maximized_horizontal = true
				c.maximized_vertical = true
			else 
				c.fullscreen = maxi
			end
		end),
    awful.key({ modkey, "Shift"   }, "q",      function (c) c:kill()                         end),
    awful.key({ modkey, "Shift"   }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end)
)


-- Compute the maximum number of digit we need, limited to 9
-- keynumber = 0
-- for s = 1, screen.count() do
--   keynumber = math.min(9, math.max(#tags[s], keynumber));
-- end

keynumber = math.min(10, #mytags)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
			awful.key({ modkey }, "#" .. i + 9,
				function ()
					if mytags[i] then
						awful.tag.viewonly(mytags[i])
						set_active_screen(awful.tag.getscreen(mytags[i]));
						-- XXX: this is only to focus active window on tag i
						awful.tag.viewtoggle(mytags[i])
						awful.tag.viewtoggle(mytags[i])
					end
				end),
			awful.key({ modkey, "Control" }, "#" .. i + 9,
				function ()
					if mytags[i] then
						awful.tag.viewtoggle(mytags[i])
					end
				end),
			awful.key({ modkey, "Shift" }, "#" .. i + 9,
				function ()
					if client.focus and mytags[i] then
						awful.client.movetotag(mytags[i])
					end
				end),
			awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
				function ()
					if client.focus and mytags[i] then
						awful.client.toggletag(mytags[i])
					end
				end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))


-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "Vlc" },
      properties = { floating = true, ontop = true, sticky = true } },
    { rule = { class = "MPlayer" },
      properties = { floating = true, ontop = true, sticky = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "Wicd-client.py" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
	{ rule = { class = "Gnuplot" },
	  properties = { floating = true, ontop = true } },
	{ rule = { type = "splash" }, 
	  properties = { border_width = 0} },
    -- Window to tag mapping
    { rule_any = { class = {"Firefox", "Iceweasel", "Chromium", "Google-chrome" } },
      properties = { tag = mytags[5] } },
    { rule = { class = "Icedove" },
      properties = { tag = mytags[6] } },
    { rule_any = { class = {"Qutim", "Xchat", "Skype", "psi"} },
      properties = { tag = mytags[7] } },
    { rule = { icon_name = ".* - CMus" },
      properties = { tag = mytags[8] } },
    { rule = { class = "sun-awt-X11-XFramePeer" },
      properties = { floating = true } },
}
-- }}}

-- {{{ Signals
client.disconnect_signal("manage", awful.tag.manage)
-- rules should be applied AFTER standart_manage_handler which i'm about
-- to hook
client.disconnect_signal("manage", awful.rules.apply)

client.connect_signal("manage", function (c, startup)
    -- If we are not managing this application at startup,
    -- move it to the screen where the mouse is.
    -- We only do it for "normal" windows (i.e. no dock, etc).
    if not startup 
		and c.type ~= "desktop" 
		and c.type ~= "dock" 
		and c.type ~= "splash" then
        if c.transient_for then
            c.screen = c.transient_for.screen
            if not c.sticky then
                c:tags(c.transient_for:tags())
            end
        else
            c.screen = activescreen
        end
    end
    c:connect_signal("property::screen", awful.tag.withcurrent)
end)
client.connect_signal("manage", awful.rules.apply)

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if 	not c.size_hints.user_position and 
			not c.size_hints.program_position then
			awful.placement.no_overlap(c)
			awful.placement.no_offscreen(c)
        end
    end

    -- Add a titlebar
    local titlebars_enabled = true
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
		local spacer = wibox.widget.textbox();
		spacer:set_text(" ");
		left_layout:add(spacer);
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("left")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) 
	if activescreen ~= c.screen then
		set_active_screen(c.screen);
	end
	c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c) 
	c.border_color = beautiful.border_normal
end)
-- }}}
