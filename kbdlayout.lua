local awful = require("awful")
local timer = require("timer")
local wibox = require("wibox")
local widget = require("wibox.widget")
local os = {getenv = os.getenv}

local setmetatable = setmetatable

module("kbdlayout")

function new(labels)
	local labels = labels or {}
	local text = widget.textbox()
	local timer = timer {timeout = 1}

	text:set_text("UNK ");

	timer:connect_signal("timeout", function() 
		local status = awful.util.pread(os.getenv("HOME") .. "/.awesome/scripts/altgroup")
		status = status:match("(%w+)")
		text:set_text(" " .. (labels[status] or status) .. " ")
	end)

	timer:start()
	
	return text
end

setmetatable(_M, {__call = function(_, ...) return new(...) end})
