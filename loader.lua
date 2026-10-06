-- SQ Services loader: own key window first, then your UI (sqservicesui.lua).
-- Users run:  loadstring(game:HttpGet("https://raw.githubusercontent.com/333shop/sqservicesui/main/loader.lua"))()
local SUPABASE_URL = "https://fgiudtvqrbflpnkjudir.supabase.co"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZnaXVkdHZxcmJmbHBua2p1ZGlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNTcwMjMsImV4cCI6MjEwNjgzMzAyM30.TApgxrIAPQTNNKGUw1YGb-QI7x3sEAq763um0sUETcM"
local UI_URL = "https://raw.githubusercontent.com/333shop/sqservicesui/main/sqservicesui.lua"
local SITE = "https://sqservices.me"
local KEY_FILE = "sqservices_key.txt"

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function guiParent()
	return (gethui and gethui()) or Players.LocalPlayer:WaitForChild("PlayerGui")
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

local function validate(key)
	local res = rpc("validate_key", { p_key = key })
	return res and res.valid and res.email or nil
end

local function gameName()
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	return ok and info.Name or "Unknown game"
end

-- ---------- on-screen errors ----------
local function fail(msg)
	warn("[sqservices loader] " .. tostring(msg))
	pcall(function()
		local gui = Instance.new("ScreenGui")
		gui.Name = "sqservicesError"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 2000
		gui.Parent = guiParent()
		local box = Instance.new("TextLabel")
		box.Size = UDim2.new(0, 420, 0, 90)
		box.Position = UDim2.new(0.5, -210, 0, 20)
		box.BackgroundColor3 = Color3.fromRGB(120, 20, 30)
		box.TextColor3 = Color3.new(1, 1, 1)
		box.TextWrapped = true
		box.Font = Enum.Font.Gotham
		box.TextSize = 14
		box.Text = "sqservices loader error:\n" .. tostring(msg)
		box.Parent = gui
		Instance.new("UICorner", box)
		task.delay(12, function() gui:Destroy() end)
	end)
end

-- ---------- load your UI ----------
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
	local Library, err = loadUI()
	if not Library then return fail(err) end

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
	-- Add your own features here, e.g.  local Tab = Window:CreateTab("Main")
end

-- ---------- your own key window ----------
local function showKeyWindow()
	local gui = Instance.new("ScreenGui")
	gui.Name = "sqservicesKey"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.IgnoreGuiInset = true
	gui.Parent = guiParent()

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 360, 0, 230)
	box.Position = UDim2.new(0.5, -180, 0.5, -115)
	box.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
	box.BackgroundTransparency = 0.12
	box.BorderSizePixel = 0
	box.Active = true
	box.Parent = gui
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", box)
	stroke.Color = Color3.fromRGB(45, 80, 150)
	stroke.Thickness = 1.3
	stroke.Transparency = 0.3

	local function text(parent, str, size, pos, font, color, h)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -28, 0, h or 20)
		t.Position = pos
		t.BackgroundTransparency = 1
		t.Text = str
		t.Font = font
		t.TextSize = size
		t.TextColor3 = color
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = parent
		return t
	end

	text(box, "sqservices.me", 18, UDim2.new(0, 14, 0, 14), Enum.Font.GothamBold, Color3.fromRGB(225, 235, 255), 26)
	local note = text(box, "Enter your key from sqservices.me", 12, UDim2.new(0, 14, 0, 44), Enum.Font.Gotham, Color3.fromRGB(145, 160, 195))

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -28, 0, 38)
	input.Position = UDim2.new(0, 14, 0, 76)
	input.BackgroundColor3 = Color3.fromRGB(20, 28, 52)
	input.BackgroundTransparency = 0.2
	input.BorderSizePixel = 0
	input.PlaceholderText = "Paste key here..."
	input.PlaceholderColor3 = Color3.fromRGB(105, 120, 155)
	input.Text = ""
	input.ClearTextOnFocus = false
	input.Font = Enum.Font.Gotham
	input.TextSize = 13
	input.TextColor3 = Color3.fromRGB(215, 225, 255)
	input.Parent = box
	Instance.new("UICorner", input).CornerRadius = UDim.new(0, 9)
	local pad = Instance.new("UIPadding", input)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)

	local function button(label, x, bg)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.5, -20, 0, 36)
		b.Position = UDim2.new(x, x == 0 and 14 or 6, 0, 130)
		b.BackgroundColor3 = bg
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 13
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = label
		b.Parent = box
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
		b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0.15 }):Play() end)
		b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play() end)
		return b
	end
	local redeem = button("Redeem", 0, Color3.fromRGB(48, 110, 215))
	local getKey = button("Get Key", 0.5, Color3.fromRGB(32, 46, 80))

	local status = text(box, "", 12, UDim2.new(0, 14, 0, 182), Enum.Font.Gotham, Color3.fromRGB(145, 160, 195), 30)
	status.TextWrapped = true
	status.TextYAlignment = Enum.TextYAlignment.Top

	getKey.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(SITE)
			getKey.Text = "Link copied"
		else
			status.Text = "Go to " .. SITE .. " to get your key"
		end
		task.delay(1.5, function() getKey.Text = "Get Key" end)
	end)

	local busy = false
	local function tryRedeem()
		local key = input.Text:gsub("%s+", "")
		if key == "" or busy then return end
		busy = true
		status.TextColor3 = Color3.fromRGB(145, 160, 195)
		status.Text = "Checking key..."
		local email = validate(key)
		if not email then
			status.TextColor3 = Color3.fromRGB(235, 90, 100)
			status.Text = "Invalid key, or the site could not be reached."
			busy = false
			return
		end
		if writefile then pcall(writefile, KEY_FILE, key) end
		gui:Destroy()
		openMain(key, email)
	end
	redeem.MouseButton1Click:Connect(function() local ok, e = pcall(tryRedeem) if not ok then busy = false fail(e) end end)
	input.FocusLost:Connect(function(enter) if enter then local ok, e = pcall(tryRedeem) if not ok then busy = false fail(e) end end end)

	-- drag by the box
	local dragging, startPos, startMouse
	box.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startPos, startMouse = true, box.Position, i.Position
		end
	end)
	box.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startMouse
			box.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- ---------- start ----------
local function main()
	if SUPABASE_URL:find("YOUR%-PROJECT") or SUPABASE_ANON_KEY:find("YOUR%-ANON") then
		return fail("Open loader.lua and paste your Supabase URL and anon key at the top.")
	end
	if isfile and readfile and isfile(KEY_FILE) then
		local saved = readfile(KEY_FILE)
		local email = validate(saved)
		if email then return openMain(saved, email) end
	end
	showKeyWindow()
end

local ok, err = pcall(main)
if not ok then fail(err) end
