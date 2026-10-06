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

local Library = loadstring(game:HttpGet(UI_URL))()

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

-- auto-login with a saved key
if isfile and readfile and isfile(KEY_FILE) then
	local saved = readfile(KEY_FILE)
	local email = validate(saved)
	if email then return openMain(saved, email) end
end

local keySystem
keySystem = Library:CreateKeySystem({
	Title = "sqservices.me",
	Link = SITE,
	Note = "Make an account on the site and copy your key",
	Callback = function(key)
		keySystem.SetNote("Checking key...")
		local email = validate(key)
		if not email then return keySystem.SetNote("Invalid key. Copy it from your dashboard.") end
		if writefile then pcall(writefile, KEY_FILE, key) end
		keySystem.Destroy()
		openMain(key, email)
	end,
})
