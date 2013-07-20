local io = io

local setmetatable = setmetatable

module("tiny")

function read_to_string(filename)
	local fd = io.open(filename)
	if not fd then
		return ""
	end
	local content = fd:read("*a")
	fd:close()
	return content
end
