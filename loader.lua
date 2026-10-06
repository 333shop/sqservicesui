-- SQ Services loader for MatchaUI: key system first, then your window.
-- Users run:  loadstring(game:HttpGet("https://raw.githubusercontent.com/333shop/sqservicesui/main/loader.lua"))()
local SUPABASE_URL = "https://fgiudtvqrbflpnkjudir.supabase.co"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZnaXVkdHZxcmJmbHBua2p1ZGlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNTcwMjMsImV4cCI6MjEwNjgzMzAyM30.TApgxrIAPQTNNKGUw1YGb-QI7x3sEAq763um0sUETcM"
-- Raw link to your MatchaUI file. Change the file name if you saved it under a different one.
local UI_URL = "https://raw.githubusercontent.com/333shop/sqservicesui/main/sqservicesui.lua"
local SITE = "https://sqservices.me"

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- ---------- on-screen errors ----------
local function fail(msg)
	warn("[sqservices loader] " .. tostring(msg))
	pcall(function()
		local gui = Instance.new("ScreenGui")
		gui.Name = "sqservicesError"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 2000
		gui.Parent = (gethui and gethui()) or Players.LocalPlayer:WaitForChild("PlayerGui")
		local box = Instance.new("TextLabel")
		box.Size = UDim2.new(0, 440, 0, 100)
		box.Position = UDim2.new(0.5, -220, 0, 20)
		box.BackgroundColor3 = Color3.fromRGB(120, 20, 30)
		box.TextColor3 = Color3.new(1, 1, 1)
		box.TextWrapped = true
		box.Font = Enum.Font.Code
		box.TextSize = 14
		box.Text = "sqservices loader error:\n" .. tostring(msg)
		box.Parent = gui
		Instance.new("UICorner", box)
		task.delay(15, function() gui:Destroy() end)
	end)
end

-- ---------- network ----------
local function rpc(fn, body)
	local payload = {
		Url = SUPABASE_URL .. "/rest/v1/rpc/" .. fn,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["apikey"] = SUPABASE_ANON_KEY,
			["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
		},
		Body = HttpService:JSONEncode(body),
	}
	local ok, res
	if httpRequest then
		ok, res = pcall(httpRequest, payload)
	else
		ok, res = pcall(function() return HttpService:RequestAsync(payload) end)
	end
	if not ok or not res or not res.StatusCode or res.StatusCode < 200 or res.StatusCode >= 300 then return nil end
	local dok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
	return dok and data or {}
end

local function gameName()
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	return ok and info.Name or "Unknown game"
end

-- ---------- load MatchaUI ----------
local function loadUI()
	local okGet, src = pcall(function() return game:HttpGet(UI_URL .. "?t=" .. os.time()) end)
	if not okGet then return nil, "Could not download the UI: " .. tostring(src) end
	if type(src) ~= "string" or src:sub(1, 3) == "404" then return nil, "UI file not found at " .. UI_URL end
	local fn, err = loadstring(src)
	if not fn then return nil, "UI file has an error: " .. tostring(err) end
	local okRun, lib = pcall(fn)
	if not okRun or type(lib) ~= "table" then return nil, "UI file did not return the library: " .. tostring(lib) end
	return lib
end

-- ---------- main window (built after the key is accepted) ----------
local function openMain(Library, key, email)
	local function sync()
		return rpc("log_game", { p_key = key, p_place = game.PlaceId, p_name = gameName() })
	end
	local synced = sync()

	local Window = Library.new({
		Title = "sqservices.me",
		Subtitle = "dashboard",
		Size = UDim2.fromOffset(640, 480),
		ToggleKey = Enum.KeyCode.RightShift,
	})

	local Home = Window:AddTab("Home")
	local acct = Home:AddSection("Account", "Left")
	acct:AddLabel("Email: " .. tostring(email))
	acct:AddLabel("Game: " .. gameName())
	local status = acct:AddLabel(synced and "Status: synced to dashboard" or "Status: sync failed")
	acct:AddButton({ Name = "Sync game", Callback = function()
		local ok = sync()
		status:Set(ok and "Status: synced to dashboard" or "Status: sync failed")
		Library:Notify(ok and "Synced to your dashboard" or "Sync failed")
	end })
	acct:AddButton({ Name = "Copy website link", Callback = function()
		if setclipboard then setclipboard(SITE) end
		Library:Notify("Copied " .. SITE)
	end })

	local info = Home:AddSection("Info", "Right")
	info:AddLabel("Menu key: RightShift")
	info:AddLabel("View your games at")
	info:AddLabel(SITE)

	-- Add your features to new tabs/sections here, e.g.
	-- local Main = Window:AddTab("Main")
	-- Main:AddSection("Combat", "Left"):AddToggle({ Name = "Example", Flag = "example" })

	local Settings = Window:AddTab("Settings")
	local look = Settings:AddSection("Appearance", "Left")
	look:AddColorPicker({ Name = "Accent color", Default = Color3.fromRGB(250, 170, 235), Callback = function(c) Library:SetAccent(c) end })
	local misc = Settings:AddSection("Menu", "Right")
	misc:AddButton({ Name = "Unload", Callback = function() Window:Destroy() end })

	Library:Notify("Welcome to sqservices.me")
end

-- ---------- start ----------
local function main()
	if SUPABASE_URL:find("YOUR%-PROJECT") or SUPABASE_ANON_KEY:find("YOUR%-ANON") then
		return fail("Open loader.lua and paste your Supabase URL and anon key at the top.")
	end

	local Library, err = loadUI()
	if not Library then return fail(err) end

	local accountKey, accountEmail
	local ok = Library:KeySystem({
		Title = "sqservices.me",
		Subtitle = "key system",
		Note = "Paste the key from your sqservices.me dashboard",
		GetKeyLink = SITE,
		FileName = "sqservices_key.txt",
		Validate = function(key)
			local res = rpc("validate_key", { p_key = key })
			if res and res.valid and res.email then
				accountKey, accountEmail = key, res.email
				return true, "Key accepted"
			end
			return false, res and "Invalid key" or "Could not reach the site"
		end,
	})

	if ok and accountKey then
		openMain(Library, accountKey, accountEmail)
	end
end

local ok, err = pcall(main)
if not ok then fail(err) end
