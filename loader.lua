-- SQ Services loader. Users run:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/333shop/sqservicesui/main/loader.lua"))()
local SUPABASE_URL = "https://fgiudtvqrbflpnkjudir.supabase.co"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZnaXVkdHZxcmJmbHBua2p1ZGlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNTcwMjMsImV4cCI6MjEwNjgzMzAyM30.TApgxrIAPQTNNKGUw1YGb-QI7x3sEAq763um0sUETcM"
local UI_URL = "https://raw.githubusercontent.com/333shop/sqservicesui/main/sqservicesui.lua"
local SITE = "https://sqservices.me"
local KEY_FILE = "sqservices_key.txt"

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

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

-- shows a red box on screen so failures are never silent
local function fail(msg)
	warn("[sqservices loader] " .. tostring(msg))
	pcall(function()
		local parent = (gethui and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		local gui = Instance.new("ScreenGui")
		gui.Name = "sqservicesError"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 2000
		gui.Parent = parent
		local box = Instance.new("TextLabel")
		box.Size = UDim2.new(0, 420, 0, 90)
		box.Position = UDim2.new(0.5, -210, 0, 20)
		box.BackgroundColor3 = Color3.fromRGB(120, 20, 30)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.TextWrapped = true
		box.Font = Enum.Font.Gotham
		box.TextSize = 14
		box.Text = "sqservices loader error:\n" .. tostring(msg)
		box.Parent = gui
		Instance.new("UICorner", box)
		task.delay(12, function() gui:Destroy() end)
	end)
end

local function loadUI()
	local okGet, src = pcall(function() return game:HttpGet(UI_URL .. "?t=" .. os.time()) end)
	if not okGet then return nil, "Could not download the UI (check the URL and your executor's HttpGet): " .. tostring(src) end
	if type(src) ~= "string" or src:sub(1, 3) == "404" then return nil, "UI file not found at " .. UI_URL end
	local fn, err = loadstring(src)
	if not fn then return nil, "UI file has an error: " .. tostring(err) end
	local okRun, lib = pcall(fn)
	if not okRun or type(lib) ~= "table" then return nil, "UI file did not return the library: " .. tostring(lib) end
	return lib
end

local Library, loadErr = loadUI()
if not Library then return fail(loadErr) end
print("[sqservices loader] UI loaded")

local function gameName()
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	return ok and info.Name or "Unknown game"
end

local function addLabel(tab, text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 20)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.Gotham
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(190, 210, 245)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = tab.Container
	return l
end

local function openMain(key, email)
	local function sync()
		return rpc("log_game", { p_key = key, p_place = game.PlaceId, p_name = gameName() })
	end
	sync()

	local Window = Library:CreateWindow({ Title = "sqservices.me" })
	local Home = Window:CreateTab("Home")
	addLabel(Home, "Account: " .. tostring(email))
	addLabel(Home, "Game: " .. gameName())
	local status = addLabel(Home, "Status: synced to your dashboard")
	Home:CreateButton({ Name = "Sync game", Callback = function()
		status.Text = sync() and "Status: synced to your dashboard" or "Status: sync failed"
	end })
	Home:CreateButton({ Name = "Copy website", Callback = function()
		if setclipboard then setclipboard(SITE) end
	end })
	-- Add your own features below, e.g. local Tab = Window:CreateTab("Main")
end

local function validate(key)
	local res = rpc("validate_key", { p_key = key })
	return res and res.valid and res.email or nil
end

local function main()
	if SUPABASE_URL:find("YOUR%-PROJECT") or SUPABASE_ANON_KEY:find("YOUR%-ANON") then
		return fail("Open loader.lua and paste your Supabase URL and anon key at the top.")
	end
	-- auto-login with a saved key
	if isfile and readfile and isfile(KEY_FILE) then
		local saved = readfile(KEY_FILE)
		local email = validate(saved)
		if email then openMain(saved, email) return end
	end

	local keySystem
	keySystem = Library:CreateKeySystem({
		Title = "sqservices.me",
		Link = SITE,
		Note = "Make an account on the site and copy your key",
		Callback = function(key)
			local ok, err = pcall(function()
			keySystem.SetNote("Checking key...")
			local email = validate(key)
			if not email then return keySystem.SetNote("Invalid key, or the site could not be reached.") end
			if writefile then pcall(writefile, KEY_FILE, key) end
			keySystem.Destroy()
			openMain(key, email)
			end)
			if not ok then fail(err) end
		end,
	})
end

local okMain, errMain = pcall(main)
if not okMain then fail(errMain) end
