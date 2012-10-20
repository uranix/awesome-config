local awful = require("awful")
local timer = require("timer")
local widget = widget
local os = {getenv = os.getenv}

local setmetatable = setmetatable

module("kbdlayout")

function new(labels)
	local labels = labels or {}
	local text = widget({type = "textbox"})
	local timer = timer {timeout = .5}

	text.text = "UNK ";

	timer:add_signal("timeout", function() 
		local status = awful.util.pread(os.getenv("HOME") .. "/.awesome/altgroup")
		status = status:match("(%w+)")
		text.text = " " .. (labels[status] or status) .. " ";
	end)

	timer:start()
	
	return text
end

setmetatable(_M, {__call = function(_, ...) return new(...) end})
