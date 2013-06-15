local awful = require("awful")
local timer = require("timer")
local wibox = require("wibox")
local widget = require("wibox.widget")
local string = {format = string.format}
local naughty = require("naughty")
local math = {floor = math.floor}

local setmetatable = setmetatable

module("battery")

function rgb(c1, c2, blend, w)
	local w1 = (1 - blend) * w;
	local w2 = blend * w
	r = c1[1] * w1 + c2[1] * w2;
	g = c1[2] * w1 + c2[2] * w2;
	b = c1[3] * w1 + c2[3] * w2;
	return string.format('#%.2x%.2x%.2x', 255 * r + 0.5, 255 * g + 0.5, 255 * b + 0.5);
end

function new(bat)
	local bat = bat
	local pb = awful.widget.progressbar({width = 10, height = 24});
	local text = widget.textbox()
	local timer = timer {timeout = 2}
	local RED = {1, 0, 0}
	local GREEN = {0, 1, 0}
	local YELLOW = {1, 1, 0}
	text:set_text(" -:-- ")
	function pb:set_charging(v)
		pb:set_value(v)
		pb:set_background_color(rgb(YELLOW, GREEN, v, 0.25))
		pb:set_border_color(rgb(YELLOW, GREEN, v, 1))
		pb:set_color(rgb(YELLOW, GREEN, v, 0.75))
	end
	function pb:set_discharging(v)
		pb:set_value(v)
		pb:set_background_color(rgb(RED, YELLOW, v, 0.25))
		pb:set_border_color(rgb(RED, YELLOW, v, 1))
		pb:set_color(rgb(RED, YELLOW, v, 0.75))
	end
	pb:set_vertical(true)
	pb:set_discharging(1)
	timer:connect_signal("timeout", function()
		local status = awful.util.pread("cat /sys/class/power_supply/" .. bat .. '/uevent')
		local charging = true;
		local now = 0
		local full = 0
		local current = 0
		for line in status:gmatch("[^\n\r]+") do
			v1, v2 = line:match("([_%w]+)=([^\n\r]*)")
			if v1 == "POWER_SUPPLY_STATUS" then
				charging = v2 ~= "Discharging"
			end
			if v1 == "POWER_SUPPLY_CHARGE_FULL" then
				full = 0 + v2;
			end
			if v1 == "POWER_SUPPLY_CHARGE_NOW" then
				now = 0 + v2;
			end
			if v1 == "POWER_SUPPLY_CURRENT_NOW" then
				current = 0 + v2;
			end
		end
		local charge = charging and (full - now) or now;
		local mins = math.floor((charge/current) * 60 + 0.5);
		local hours = math.floor(mins / 60);
		mins = mins - 60 * hours;
		if current < 500000 then
			text:set_text(" -:-- ")
		else
			text:set_text(string.format(" %d:%02d ", hours, mins))
		end
		local v = now / full
		if charging then
			pb:set_charging(v)
		else
			pb:set_discharging(v)
		end
	end)
	timer:start()
	local layout = wibox.layout.fixed.horizontal();
	layout:add(pb);
	layout:add(text);
	return layout
end

setmetatable(_M, {__call = function(_, ...) return new(...) end})
