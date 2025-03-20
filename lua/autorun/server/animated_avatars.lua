local IsURL = function(str)
	return string.find(str, "(|?%a[%w+.%-]-://[%w%-._~:/?#%[%]@!$&'()*+,;=%%]+)")
end

hook.Add("NetData", "animated_avatars.Network", function(id, key, value)
	local CVar = animated_avatars.CVars[key]
	if not CVar then
		return
	end

	local validator = CVar["validate"]
	local f = validator()
	if f ~= nil then
		return f
	end
end)