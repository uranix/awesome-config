local awful = require("awful")
local timer = require("timer")
local wibox = require("wibox")
local widget = require("wibox.widget")
local string = {format = string.format}
local naughty = require("naughty")
local math = {floor = math.floor}
local json = require("json")
local type = type

local setmetatable = setmetatable

module("mail")

unread = "/usr/share/icons/gnome/24x24/status/mail-unread.png"
read = "/usr/share/icons/gnome/24x24/status/mail-read.png"
offline = "/usr/share/icons/gnome/24x24/status/stock_dialog-error.png"

function new(filter)
	local ib = widget.imagebox()
	local text = widget.textbox()
	local timer = timer {timeout = 5}
	local total = 0;
	ib:set_image(offline)
	text:set_text(" 0 ")
	timer:connect_signal("timeout", function()
		local status = awful.util.pread("nc -w 1 localhost 3411")
		total = 0;
		if status == "" then
			ib:set_image(offline)
		else
			status = json.decode(status);
			for i = 1, #status do
				if filter(status[i].name) then
					total = total + status[i].unread
				end
			end
			ib:set_image((total ~= 0) and unread or read)
		end
		text:set_text(string.format(" %d ", total))
	end)
	timer:start()
	local layout = wibox.layout.fixed.horizontal();
	layout:add(ib);
	layout:add(text);
	return layout
end

setmetatable(_M, {__call = function(_, ...) return new(...) end})
