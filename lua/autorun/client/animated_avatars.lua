if IsValid(LocalPlayer()) then
	return
end

-- всем привет https://mavrodi.kappa.lol/9Da6D.gif

local pairs = pairs
local _print = print
local CVar_Developer = GetConVar("developer")

local print = function(...)
	if CVar_Developer:GetInt() <= 0 then return end
	MsgC(Color(255, 0, 0), "Animated Avatars > ") _print(...)
end

file.CreateDir("steam_avatars_cache")

local botsSteamIDs = {}
local getAvatarsHTML = setmetatable({}, {__mode = "v"})
local avatars = {}
function steam_avatar_clear_cache()
	local files = file.Find("steam_avatars_cache/*", "DATA")

	if files then
		for key, value in pairs(files) do
			file.Delete("steam_avatars_cache/" .. value)
		end
	end

	return true
end

hook.Add("ShutDown", "steam_avatars_cache_clear", steam_avatar_clear_cache)
steam_avatar_clear_cache()

local HTML_GIF = [[<style>img {text-align: center;position: absolute;margin: auto;top: 0;right: 0;bottom: 0;left: 0;width: 99%;height: 99%;}</style>
<img id="elem" src="{URL}"></img>
<script>
document.getElementById('elem').onload = function() { console.log("1"); };
</script>]]

vgui_Create = vgui_Create or vgui.Create
local vgui_Create = vgui_Create

local i = 0
local color_black = Color(40, 40, 40)
local scale_x, scale_y = 184 / 128, 184 / 128
local SysTime = SysTime
local qc = {}
local function RotatedBox( x, y, w, h, ang, color )
	draw.NoTexture()
	surface.SetDrawColor( color or color_white )
	surface.DrawTexturedRectRotated( x, y, w, h, ang )
end

local color_white_2 = Color(220, 220, 220)
function vgui.Create(str, parent, ...)
	if str == "AvatarImage" then
		local returned_panel = vgui_Create("DPanel", parent)
		returned_panel.AlphaMult = 0
		local color_gray = Color(80, 80, 80)

		i = i + 1

		returned_panel.NextUpdate = SysTime() + 3
		returned_panel.Paint = function(self, w, h)
			if self.CurrentSteamID
				and botsSteamIDs[self.CurrentSteamID] then

				draw.RoundedBox(0, 0, 0, w, h, color_black)
				RotatedBox(0, 0, 2, h * 3, -135, color_white_2)
				RotatedBox(w, 0, 2, h * 3, 135, color_white_2)
				return
			end

			local sysTime = SysTime()
			if self.Mat then
				local url = self.URL
				if url then
					qc[url] = SysTime() + 1

					local html = getAvatarsHTML[url]
					if IsValid(html) then
						html:SetVisible(true)
					end
				end

				surface.SetMaterial(self.Mat)
				surface.SetDrawColor(255, 255, 255)
				surface.DrawTexturedRect(0, 0, w * 2 + 1, h * 2 + 1)
			else
				if self.CurrentSteamID
					and (self.NextUpdate or 0) < sysTime then
					self.NextUpdate = sysTime + 3
					self:SetSteamID(self.CurrentSteamID)
				end

				local form = math.abs(math.cos((sysTime + i) * 4) * 25)
				color_gray.r = 80 + form
				color_gray.g = 80 + form
				color_gray.b = 80 + form

				draw.RoundedBox(0, 0, 0, w, h, color_black)
				draw.RoundedBox(0, 2, 2, w - 4, h - 4, color_gray)
			end
		end

		return returned_panel
	end

	return vgui_Create(str, parent, ...)
end

local GetAvatar
GetAvatar = function(val, handleURL, handleError)
	if botsSteamIDs[val] then
		if handleURL then
			handleURL("bot")
		end

		return
	end

	local steamID = isentity(val) and val:SteamID64() or val
	local fileName = string.format("steam_avatars_cache/%s.dat", steamID)
	local assetPath = string.format("asset://garrysmod/data/steam_avatars_cache/%s.dat", steamID)
	if file.Exists(fileName, "DATA") then
		return handleURL and handleURL(assetPath)
	end

	local ply = isentity(val) and val or player.GetBySteamID64(steamID)
	if ply then
		if ply:IsBot() then
			botsSteamIDs[ply] = true
			botsSteamIDs[steamID] = true

			if handleURL then
				handleURL("bot")
			end

			return
		end

		local customAvatar = ply:GetNetData("cl_animated_avatars_url")
		if customAvatar ~= nil
			and string.Trim(customAvatar) ~= "" then
			http.Fetch(customAvatar, function(body, _, _, code)
				if code ~= 200 then
					if handleError then
						handleError("on avatar fetching: " .. code, body)
					end

					return
				end

				file.Write(fileName, body)
				
				if handleURL then
					handleURL(assetPath)
				end
			end, function()
				if handleError then
					handleError("invalid url: " .. customAvatar)
				end
			end)

			return
		end
	end

	http.Fetch(string.format("https://steamcommunity.com/profiles/%s", steamID), function(body, _, _, code)
		if code ~= 200 then
			if handleError then
				handleError(code, body)
			end

			return
		end

		local url = ""

		for _, pattern in ipairs({
			'<div class="playerAvatarAutoSizeInner".-</div></div>',
			'<div class="playerAvatarAutoSizeInner".-</div>'
		}) do
			local div = string.match(body, pattern)
			if div then
				for img in string.gmatch(div, '<img src="(.-)"') do
					url = img
				end

				if url ~= "" then
					http.Fetch(url, function(body, _, _, code)
						if code ~= 200 then
							if handleError then
								handleError("on avatar fetching: " .. code, body)
							end

							return
						end

						file.Write(fileName, body)

						if handleURL then
							handleURL(assetPath)
						end
					end)

					break
				end
			end
		end

		if url == ""
			and handleError then
			timer.Create("avatars.Retrying: " .. steamID, 1, 1, function()
				GetAvatar(steamID, handleURL, handleError)
			end)
		end
	end)
end

local changeAvatars = setmetatable({}, {__mode = "k"})
local precached = {}
local PANEL = FindMetaTable("Panel")
local UpdateHTMLTexture, GetHTMLMaterial = PANEL.UpdateHTMLTexture, PANEL.GetHTMLMaterial

local SetURL
SetURL = function(self, url, ply, w, h)
	local html = getAvatarsHTML[url]
	local name = string.format("%s%s%s-anti-reload30", url, tostring(w), tostring(h))
	if IsValid(html) then
		avatars[name] = CreateMaterial(name, "UnlitGeneric", {
			["$vertexcolor"] = "1",
			["$vertexalpha"] = "1",
			["$nolod"] = "1",
			["$basetexturetransform"] = "center 0 0 scale ".. scale_x .." ".. scale_y .." rotate 0 translate 0 0",
			["$basetexture"] = html:GetHTMLMaterial():GetName(),
		})

		if IsValid(self) then
			self.Mat = avatars[name]
			self.URL = url
		end

		return
	end

	if precached[url] then
		return
	end

	precached[url], qc[url] = true, SysTime() + 1

	local HTML = vgui.Create("DHTML")
	HTML:SetSize(184, 184)
	HTML:SetHTML(HTML_GIF:Replace("{URL}", url))
	HTML:SetPos(ScrW() - 1, ScrH() - 1)

	local nextThink = -1
	local getPlayer = isentity(ply) and ply or player.GetBySteamID64(ply)

	HTML.Think = function()
	 	if nextThink > SysTime() then return end
	 	nextThink = SysTime() + 0.5
	 
	 	if not IsValid(getPlayer) then
	 		return
	 	end
	 	
	 	local netData = getPlayer:GetNetData("cl_animated_avatars_url")
		if isstring(netData) and netData:Trim() == "" then
			netData = nil
		end

	 	if netData == changeAvatars[getPlayer] then
	 		return
	 	end

		changeAvatars[getPlayer] = netData
		self.NextUpdate, self.Mat = SysTime() + 3, nil

		local trigger = function(newURL)
			precached[url], qc[url] = nil, nil
			url = newURL
			precached[newURL], qc[newURL] = nil, nil
			HTML:Remove()
			SetURL(self, url, getPlayer, w, h)
		end

		file.Delete(string.format("steam_avatars_cache/%s.dat", getPlayer:SteamID64()))

		if netData ~= nil then
			trigger(netData)
		else
			GetAvatar(getPlayer, trigger)
		end
	end

	HTML.ConsoleMessage = function(_, msg)
		if msg ~= "1" then
			return
		end

		local timer_name = "avatar.Fetch: " .. url
		timer.Create(timer_name, 0, 0, function()
			if not HTML:IsValid() then
				return timer.Remove(timer_name)
			end

			local html_mat = HTML:GetHTMLMaterial()
			if not html_mat then
				return
			end

			timer.Remove(timer_name)

			avatars[name] = CreateMaterial(name, "UnlitGeneric", {
				["$vertexcolor"] = "1",
				["$vertexalpha"] = "1",
				["$nolod"] = "1",
				["$basetexturetransform"] = "center 0 0 scale ".. scale_x .." ".. scale_y .." rotate 0 translate 0 0",
				["$basetexture"] = html_mat:GetName(),
			})

			getAvatarsHTML[url] = HTML

			if IsValid(self) then
				self.Mat = avatars[name]
				self.URL = url
			end
		end)
	end
end

local PANEL = FindMetaTable("Panel")
PANEL._SetPlayer = PANEL._SetPlayer or PANEL.SetPlayer
PANEL._SetSteamID = PANEL._SetSteamID or PANEL.SetSteamID

local queue = {}

function PANEL:SetPlayer(ply, ...)
	self.CurrentSteamID = ply:SteamID64()

	local w, h = self:GetSize()
	GetAvatar(self.CurrentSteamID, function(url)
		table.insert(queue, {
			["self"] = self,
			["url"] = url,
			["ply"] = ply,
			["w"] = w,
			["h"] = h
		})
	end, print)
end

function PANEL:SetSteamID(steamID64, ...)
	self.CurrentSteamID = steamID64

	local w, h = self:GetSize()
	GetAvatar(self.CurrentSteamID, function(url)
		table.insert(queue, {
			["self"] = self,
			["url"] = url,
			["ply"] = steamID64,
			["w"] = w,
			["h"] = h
		})
	end, print)
end

hook.Add("StartCommand", "avatars.Start", function(ply, cmd)
	if cmd:IsForced() then
		return
	end

	hook.Remove("StartCommand", "avatars.Start")

	for _, ply in ipairs(player.GetAll()) do
		GetAvatar(ply:SteamID64(), function(url)
			print(string.format("Avatar %s cached: %s", ply:Name(), url))
		end)
	end

	hook.Add("Think", "avatars.Think", function()
		local firstQueue = queue[1]
		if not firstQueue then
			return
		end

		SetURL(firstQueue["self"], firstQueue["url"], firstQueue["ply"], firstQueue["w"], firstQueue["h"])

		table.remove(queue, 1)
	end)

	hook.Add("PostRender", "avatars.Render", function()
		local sysTime = SysTime()

		for url, time in pairs(qc) do
			local html = getAvatarsHTML[url]

			if IsValid(html) then
				if time > sysTime then
					UpdateHTMLTexture(html)
					html.CurrentFrameMaterial = GetHTMLMaterial(html)
				else
					html:SetVisible(false)
					qc[url] = nil
				end
			end
		end
	end)
	
	hook.Run("animated_avatars.Started")
end)

hook.Add("PlayerDisconnected", "steam_avatar_cache", function(ply)
	file.Delete(string.format("steam_avatars_cache/%s.dat", ply:SteamID64()))
end)

hook.Add("OnEntityCreated", "steam_avatar_cache", function(ply)
	if not ply:IsPlayer() then
		return
	end

	file.Delete(string.format("steam_avatars_cache/%s.dat", ply:SteamID64()))
	GetAvatar(ply:SteamID64())
end)
