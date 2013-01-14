local awful = require("awful")
local timer = require("timer")
local widget = widget
local image = image
local string = {format = string.format}
local naughty = require("naughty")
local math = {floor = math.floor}
local type = type
local os = {getenv = os.getenv}

local setmetatable = setmetatable

module("cpu")

veryhot = image("/usr/share/icons/gnome/24x24/status/software-update-urgent.png")
hot = image("/usr/share/icons/gnome/24x24/status/software-update-available.png")
norm = image(os.getenv("HOME") .. "/.awesome/cpu-norm.png")
offline = image("/usr/share/icons/gnome/24x24/status/stock_dialog-error.png")

function new()
	local ib = widget({type = "imagebox"})
	local text = widget({type = "textbox"})
	local timer = timer {timeout = 2}
	local curr_user = 0
	local curr_nice = 0
	local curr_sys = 0
	local curr_idle = 0
	local curr_total = 0
	local prev_idle = 0
	local prev_total = 0
	local diff_idle = 0
	local diff_total = 0
	local usage = 0
	local loada

	ib.image = offline
	text.text = " 0% 0.00 "
	timer:add_signal("timeout", function()
		local status = awful.util.pread("cat /proc/stat")
		local loadavg = awful.util.pread("cat /proc/loadavg")
		usage = 0
		loada = 0
		if status == "" or loadavg == "" then
			ib.image = offline
		else
			curr_user, curr_nice, curr_sys, curr_idle = 
				status:match("cpu%s+(%w+) (%w+) (%w+) (%w+) *")
			loada = 0 + loadavg:match("([%p%w]+) *")
			curr_total = curr_user + curr_nice + curr_sys + curr_idle
			diff_total = curr_total - prev_total
			diff_idle = curr_idle - prev_idle
			prev_idle = curr_idle
			prev_total = curr_total
			usage = (1000 * (diff_total - diff_idle)/diff_total + 5) / 10
			local ishot = (usage > 12 or loada > 1.5)
			local isveryhot =  (usage > 50 or loada > 2.5)
			if isveryhot then
				ib.image = veryhot
			else if ishot then
					ib.image = hot
				else 
					ib.image = norm
				end
			end
		end
		text.text = string.format(" %02d%% %.2f ", usage, loada)
	end)
	timer:start()
	return {text, ib, layout = awful.widget.layout.horizontal.rightleft}
end

setmetatable(_M, {__call = function(_, ...) return new(...) end})
