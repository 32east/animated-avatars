include("includes/modules/ubit.lua")

animated_avatars = animated_avatars or {}
animated_avatars.CVars = animated_avatars.CVars or {}

local CLIENT = CLIENT
local CVar_Create = function(cvar_info)
	local cvar_name = cvar_info["name"]
	if CLIENT then
		local ply = LocalPlayer()
		animated_avatars.CVars[cvar_name] = CreateClientConVar(cvar_name, cvar_info["default"] or "", true, false, cvar_info["description"])
		cvars.AddChangeCallback(cvar_name, function(_, _, newValue)
			if newValue:Trim() == "" then
				newValue = nil
			end

			ply:SetNetData(cvar_name, newValue)
		end, cvar_name)

		
		ply:SetNetData(cvar_name, animated_avatars.CVars[cvar_name]:GetString())
	else
		animated_avatars.CVars[cvar_name] = cvar_info
	end
end

animated_avatars.Init = function()
	CVar_Create({
		["name"] = "cl_animated_avatars_url",
		["default"] = "",
		["description"] = "Allows you to change your avatar based on a url",
		["validate"] = function(id, key, value)
			return (isstring(value) and IsURL(value)) or value == nil
		end,
	})

	-- ...
end

hook.Add("Think", "animated_avatars.Init", function()
	if (CLIENT and IsValid(LocalPlayer()))
		or SERVER then
		hook.Remove("Think", "animated_avatars.Init")
		animated_avatars.Init()
	end
end)