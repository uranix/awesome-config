-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
require("awful.tag")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
naughty.config.default_preset.icon_size = 32
naughty.config.default_preset.icon = "/usr/share/icons/Amaranth/64x64/status/dialog-info.png"

require("battery")
require("mail")
require("cpu")
require("mixer")
require("kbdlayout")

-- Calendar
require("cal")

function debug(message)
	naughty.notify({text = message})
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
    awesome.add_signal("debug::error", function (err)
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
beautiful.init(os.getenv("HOME") .. "/.awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor
awe_exit = os.getenv("HOME") .. "/.awesome/awe-exit"
awe_lock = os.getenv("HOME") .. "/.awesome/awe-lock"
brightness_less = os.getenv("HOME") .. "/.awesome/brightness_less"
brightness_more = os.getenv("HOME") .. "/.awesome/brightness_more"

awful.util.spawn(os.getenv("HOME") .. "/.awesome/startup")

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
--    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
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
	naughty.config.default_preset.screen = activescreen;
end

function spawn_on_active_screen(cmd)
	awful.util.spawn(cmd, nil, activescreen);
end

tagall = {
	{name = "1",        layout = awful.layout.suit.tile, screen = 1 },
	{name = "2",        layout = awful.layout.suit.tile, screen = 2 },
	{name = "3",        layout = awful.layout.suit.tile, screen = 1 },
	{name = "4",        layout = awful.layout.suit.tile, screen = 1 },
	{name = "5: www",   layout = awful.layout.suit.tile,  screen = 2 },
	{name = "6: mail"  ,layout = awful.layout.suit.tile,  screen = 2 },
	{name = "7: im",    layout = awful.layout.suit.tile,  screen = 2 },
	{name = "8: music", layout = awful.layout.suit.tile,  screen = 2 },
	{name = "9: video", layout = awful.layout.suit.tile,  screen = 2 },
}
--for s = 1, screen.count() do
--    -- Each screen has its own tag table.
--    tags[s] = awful.tag({ 1, 2, 3, 4, "5: www", "6: mail", "7: im", "8: music", "9: video"}, s, layouts[1])
--end

for i, tset in ipairs(tagall) do
	mytags[i] = tag({name = tset.name})
	mytags[i].screen = math.min(screen.count(), tset.screen)
	awful.tag.setproperty(mytags[i], "layout", tset.layout);
end
mytags[1].selected = true
mytags[2].selected = true

-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock.new({ align = "right"}, " %a %d %b, %H:%M:%S ", 1)
-- Show calendar on hover
cal.register(mytextclock, "<span color=\"#00c000\"><b>%s</b></span>")

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, 
	function (c)
		set_active_screen(c.screen)
		awful.tag.viewonly(c);
	end),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
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
                                          end))

-- Simple charge indicator
mychargeindicator = battery("BAT1")

-- Mail indicator
mymailindicator = mail(function (x) 
	return 
		x == "tsybulinhome@gmail.com" or
		x == "uranix@parallels.mipt.ru"
end)

-- Cpu indicator
mycpuindicator = cpu()

-- Mixer indicator
activevolumecontrol = {device = 0, control = "Speaker"}

myvolumeindicator = mixer({
	{alias = "Intel", control = "Headphone", name = "Head"},
	{alias = "Intel", control = "Speaker", name = "Speak"},
	{alias = "Device", control = "PCM", name = "Usb"}
}, activevolumecontrol)

-- Layout indicator
mylayoutindicator = kbdlayout({on = "RU", off = "US"});

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", height = 24, screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
			mylayoutbox[s],
--            s == 1 and mylauncher or widget({type = "textbox"}),
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        s == 1 and mytextclock or nil,
        s == 1 and mysystray or nil,
        s == 1 and mychargeindicator or nil,
        s == 1 and mymailindicator or nil,
        s == 1 and mycpuindicator or nil,
        s == 1 and myvolumeindicator or nil,
        s == 1 and mylayoutindicator or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
	awful.button({ }, 1, function()
		set_active_screen(mouse.screen)
	end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Global bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
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
    awful.key({ modkey,           }, "space", function () spawn_on_active_screen(terminal) end),
    awful.key({ modkey, "Shift"   }, "r", awesome.restart),
    awful.key({ modkey,           }, "q", function () awful.util.spawn(awe_lock) end),
    awful.key({ modkey, "Shift"   }, "e", 
		function () spawn_on_active_screen(awe_exit) end),
    awful.key({					  }, "XF86PowerOff", 
		function () spawn_on_active_screen(awe_exit) end),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
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
	awful.key({}, "XF86AudioRaiseVolume", function()
			awful.util.spawn(string.format('amixer -D hw:%d -q set %s 5%%+', activevolumecontrol.device, activevolumecontrol.control))
		end),
	awful.key({}, "XF86AudioLowerVolume", function()
			awful.util.spawn(string.format('amixer -D hw:%d -q set %s 5%%-', activevolumecontrol.device, activevolumecontrol.control))
		end),
	awful.key({}, "XF86AudioMute", function()
			awful.util.spawn(string.format('amixer -D hw:%d -q sset %s toggle', activevolumecontrol.device, activevolumecontrol.control))
		end),
	awful.key({}, "XF86MonBrightnessDown", function()
			awful.util.spawn(brightness_less)
		end),
	awful.key({}, "XF86MonBrightnessUp", function()
			awful.util.spawn(brightness_more)
		end),
	awful.key({}, "XF86Launch1", function()
			local status = 1 - awful.util.pread("cat /proc/easy_backlight");
			local message = {"Off", "On"}
			awful.util.spawn_with_shell(
				"echo " .. status .. " > /proc/easy_backlight")
			naughty.notify({
				text = "Backlight status: " .. message[status+1], 
				title = "Backlight",
				icon = "/usr/share/icons/gnome/32x32/status/messagebox_info.png"
				})
			-- Toggle backlight
		end),
	awful.key({}, "XF86Launch2", function()
			local output = awful.util.pread("/usr/sbin/rfkill list bluetooth")
			local start = 0
			local status = 0
			start, status = output:find("Soft blocked: ")
			local yeno = output:sub(status + 1, status + 2) 
			local message = {["ye"] = "On", ["no"] = "Off"}
			local command = {["ye"] = "unblock", ["no"] = "block"}
			awful.util.spawn("/usr/sbin/rfkill " .. command[yeno] .. " bluetooth")
			naughty.notify({
				text = "Bluetooth status: " .. message[yeno],
				title = "Bluetooth",
				icon = "/usr/share/icons/oxygen/32x32/apps/preferences-system-bluetooth.png"
				})
			-- Toggle bluetooth
		end),
	awful.key({}, "XF86Launch3", function()
			local status = 1 + awful.util.pread("cat /proc/easy_slow_down_manager");
			if status > 2 then 
				status = 0 
			end
			local message = {"Slow", "Medium", "Fast"}
			awful.util.spawn_with_shell(
				"echo " .. status .. " > /proc/easy_slow_down_manager")
			naughty.notify({
				text = "Cpu cooling status: " .. message[status+1], 
				title = "Cpu",
				icon = "/usr/share/icons/oxygen/32x32/devices/cpu.png"
				})
			-- Toggle cpu
		end),
	awful.key({}, "XF86Display", function()
			awful.util.spawn("disper --cycle-stages=' -s : -e ' -C");
		end),
	awful.key({}, "XF86WLAN", function()
			local status = 1 - awful.util.pread("cat /proc/easy_wifi_kill");
			local message = {"Off", "On"}
			awful.util.spawn_with_shell(
				"echo " .. status .. " > /proc/easy_wifi_kill")
			naughty.notify({
				text = "WiFi status: " .. message[status+1], 
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

keynumber = math.min(9, #mytags)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
			awful.key({ modkey }, "#" .. i + 9,
				function ()
					if mytags[i] then
						awful.tag.viewonly(mytags[i])
						set_active_screen(mytags[i].screen);
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
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Window to tag mapping
    { rule_any = { class = {"Firefox", "Iceweasel" } },
      properties = { tag = mytags[5] } },
    { rule = { class = "Icedove" },
      properties = { tag = mytags[6] } },
    { rule_any = { class = {"Qutim", "Xchat", "Skype"} },
      properties = { tag = mytags[7] } },
    { rule = { icon_name = "cmus" },
      properties = { tag = mytags[8] } },
    { rule_any = { class = { "Vlc", "MPlayer"} },
      properties = { tag = mytags[9] } },
}
-- }}}

-- {{{ Signals
client.remove_signal("manage", awful.tag.standart_manage_handler)
-- rules should be applied AFTER standart_manage_handler which i'm about
-- to hook
client.remove_signal("manage", awful.rules.apply)

client.add_signal("manage", function (c, startup)
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
    c:add_signal("property::screen", awful.tag.withcurrent)
end)
client.add_signal("manage", awful.rules.apply)

-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    awful.titlebar.add(c, { modkey = modkey })

    --[[ -- Enable sloppy focus
	c:add_signal("mouse::enter", function(c)
		if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
			and awful.client.focus.filter(c) then
			client.focus = c
		end
	end)
	--]]

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

end)

client.add_signal("focus", function(c) 
	if activescreen ~= c.screen then
		set_active_screen(c.screen);
	end
	c.border_color = beautiful.border_focus 
end)

client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
