local awful = require("awful")
local timer = require("timer")
local wibox = require("wibox")
local widget = require("wibox.widget")
local string = {format = string.format}
local naughty = require("naughty")
local math = {floor = math.floor}
local table = {insert = table.insert}
local os = {getenv = os.getenv}
local tiny = require("tiny")

local setmetatable = setmetatable

module("mixer")

local RED = {1, 0, 0}
local GREEN = {0, 1, 0}
local GRAY = {.5, .5, .5}

function rgb(c1, c2, blend, w)
	local w1 = (1 - blend) * w;
	local w2 = blend * w
	r = c1[1] * w1 + c2[1] * w2;
	g = c1[2] * w1 + c2[2] * w2;
	b = c1[3] * w1 + c2[3] * w2;
	return string.format('#%.2x%.2x%.2x', 255 * r + 0.5, 255 * g + 0.5, 255 * b + 0.5);
end

function disable(self)
	self:set_value(0)
	local m = 0
	self:set_background_color(rgb(GRAY, GRAY, m, 0.25))
	self:set_border_color(rgb(GRAY, GRAY, m, 1))
	self:set_color(rgb(GRAY, GRAY, m, 0.75))
end

function set(self, v, mute)
	self:set_value(v)
	local m = mute and 1 or 0
	self:set_background_color(rgb(GREEN, RED, m, 0.25))
	self:set_border_color(rgb(GREEN, RED, m, 1))
	self:set_color(rgb(GREEN, RED, m, 0.75))
end

function new(items, activecontrol)
	local items = items
	local n = # items
	local ret = {insert = table.insert}
	local pbars = {}
	local labels = {}
	local ordinals = {}
	local handlers = {}
	for i = 1,n do
		pbars[i] = awful.widget.progressbar({width = 10, height = 24})
		pbars[i].set = set
		pbars[i].disable = disable
		pbars[i]:set_vertical(true)
		pbars[i]:set(0, true)
		handlers[i] = function() 
			j = ordinals[items[i].alias]
			if not j then
				return
			end
			activecontrol.device = j;
			activecontrol.control = items[i].control;
		end
		pbars[i]:buttons(awful.button({ }, 1, handlers[i]))
		labels[i] = widget.textbox()
		labels[i]:set_text(" " .. items[i].name .. " ")
		labels[i]:buttons(awful.button({ }, 1, handlers[i]))
		ret:insert(labels[i])
		ret:insert(pbars[i])
	end
	local timer = timer {timeout = 2}
	timer:connect_signal("timeout", function()
		local status = tiny.read_to_string("/proc/asound/cards");
		local cards = status:gmatch("[^\n]+\n[^\n]+")
		ordinals = {}
		for card in cards do
			local num
			local name
			num, name = card:match("%s+(%d+)%s+%[(%w+)%s+%]*")
			ordinals[name] = num
		end
		for i = 1,n do
			local alias = items[i].alias
			local cha = items[i].control
			local j = ordinals[alias]
			if j then
				local amixerout = awful.util.pread(string.format("amixer -D hw:%s sget %s", j, cha));
				local status = ""
				for line in amixerout:gmatch("[^\n]+") do
					status = line
				end
				local name, junk1, junk2, per, db1, db2, mute = 
					status:match("(.*)%: (%w+) (%d+) %[(%d+)%%%] %[([-%d]+)%.(%d+)dB%] %[(%w+)%]")
				if per and mute then
					mute = mute == "off"
					level = (0 + per) / 100
					pbars[i]:set(level, mute)
				end
				if (j == "" .. activecontrol.device) and (cha == activecontrol.control) then
					for k = 1,n do
						labels[k]:set_text(string.format(" %s ", items[k].name))
					end
					labels[i]:set_markup(string.format(" <b>%s</b> ", items[i].name))
				end
			else
				pbars[i]:disable()
			end
		end
	end)
	timer:start()
	local layout = wibox.layout.fixed.horizontal();
	for i = #ret,1,-1 do
		layout:add(ret[i]);
	end
	return layout
end

setmetatable(_M, {__call = function(_, ...) return new(...) end})
