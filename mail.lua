local awful = require("awful")
local timer = require("timer")
local widget = widget
local image = image
local string = {format = string.format}
local naughty = require("naughty")
local math = {floor = math.floor}
local json = require("json")
local type = type

local setmetatable = setmetatable

module("mail")

unread = image("/usr/share/icons/gnome/24x24/status/mail-unread.png")
read = image("/usr/share/icons/gnome/24x24/status/mail-read.png")
offline = image("/usr/share/icons/gnome/24x24/status/stock_dialog-error.png")

function new(filter)
	local ib = widget({type = "imagebox"})
	local text = widget({type = "textbox"})
	local timer = timer {timeout = 2}
	local total = 0;
	ib.image = offline
	text.text = " 0 "
	timer:add_signal("timeout", function()
		local status = awful.util.pread("nc localhost 3411")
		total = 0;
		if status == "" then
			ib.image = offline
		else
			status = json.decode(status);
			for i = 1, #status do
				if filter(status[i].name) then
					total = total + status[i].unread
				end
			end
			ib.image = (total ~= 0) and unread or read
		end
		text.text = string.format(" %d ", total)
	end)
	timer:start()
	return {text, ib, layout = awful.widget.layout.horizontal.rightleft}
end

setmetatable(_M, {__call = function(_, ...) return new(...) end})
