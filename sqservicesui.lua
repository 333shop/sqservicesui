--[[
    MatchaUI  -  dark / flat / two-column UI library (Roblox, Luau)
    Layout inspired by ImGui-style menus: top tabs, grouped sections, pink accent.

    Window   : Library.new{Title, Subtitle, Size, ToggleKey, Icon}
    Tabs     : Window:AddTab(name)
    Sections : Tab:AddSection(name, "Left" | "Right")
    Elements : Section:AddToggle / AddSlider / AddDropdown / AddKeybind /
               AddColorPicker / AddButton / AddTextbox / AddLabel / AddDivider /
               AddViewport
    Extras   : Window:AddFloatingViewport, Library:KeySystem, Library:Notify,
               Library:SaveConfig / LoadConfig, Library:SetAccent
]]

local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")

local Library = { Options = {}, ConfigFolder = "MatchaUI", _binds = {} }
Library.Flags = setmetatable({}, {
	__index = function(_, k)
		local o = Library.Options[k]
		return o and o.Value
	end,
})

local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section

local Theme = {
	Background = Color3.fromRGB(14, 14, 14),
	Panel      = Color3.fromRGB(22, 22, 22),
	Element    = Color3.fromRGB(36, 36, 36),
	Stroke     = Color3.fromRGB(44, 44, 44),
	Text       = Color3.fromRGB(235, 235, 235),
	Dim        = Color3.fromRGB(140, 140, 140),
	Accent     = Color3.fromRGB(250, 170, 235),
	Font       = Enum.Font.Code,
}

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------
local accentFns = {}
local function bindAccent(fn)
	table.insert(accentFns, fn)
	fn(Theme.Accent)
end

function Library:SetAccent(color)
	Theme.Accent = color
	for _, fn in ipairs(accentFns) do pcall(fn, color) end
end

local function tween(o, props, t)
	TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function new(class, props)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end

local function corner(o, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 4), Parent = o })
end

local function stroke(o, c)
	return new("UIStroke", { Color = c or Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
end

local function pad(o, l, t, r, b)
	t = t or l; r = r or l; b = b or t
	new("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b), Parent = o,
	})
end

local function list(o, p, dir)
	return new("UIListLayout", {
		Padding = UDim.new(0, p or 0), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = dir or Enum.FillDirection.Vertical, Parent = o,
	})
end

local function label(parent, str, extra)
	local p = {
		BackgroundTransparency = 1, Text = str, Font = Theme.Font, TextSize = 13,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
	}
	for k, v in pairs(extra or {}) do p[k] = v end
	return new("TextLabel", p)
end

local function getParent()
	local ok, res = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
	if ok and res then return res end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function makeGui(name)
	local g = new("ScreenGui", {
		Name = name, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true, DisplayOrder = 999,
	})
	g.Parent = getParent()
	return g
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function keyName(k)
	if not k then return "none" end
	if k.EnumType == Enum.UserInputType then
		local n = k.Name:gsub("MouseButton", "mouse")
		return n:lower()
	end
	return k.Name:lower()
end

local function matches(i, k)
	if k.EnumType == Enum.KeyCode then return i.KeyCode == k end
	return i.UserInputType == k
end

local function parseKey(s)
	if type(s) ~= "string" or s == "" then return nil end
	local parts = string.split(s, ".")
	local ok, v = pcall(function() return Enum[parts[2]][parts[3]] end)
	return ok and v or nil
end

local function makeDraggable(handle, target, win)
	local drag, startPos, startFrame = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if isPress(i) then drag, startPos, startFrame = true, i.Position, target.Position end
	end)
	win:_connect(UIS.InputEnded, function(i) if isPress(i) then drag = false end end)
	win:_connect(UIS.InputChanged, function(i)
		if drag and isMove(i) then
			local d = i.Position - startPos
			target.Position = UDim2.new(startFrame.X.Scale, startFrame.X.Offset + d.X, startFrame.Y.Scale, startFrame.Y.Offset + d.Y)
		end
	end)
end

-- global keybind dispatcher
UIS.InputBegan:Connect(function(i, gp)
	if gp or Library._listening then return end
	for _, b in ipairs(Library._binds) do
		local k = b.Get()
		if k and matches(i, k) then b.Down() end
	end
end)
UIS.InputEnded:Connect(function(i)
	for _, b in ipairs(Library._binds) do
		local k = b.Get()
		if k and b.Up and matches(i, k) then b.Up() end
	end
end)

----------------------------------------------------------------
-- keybind box (shared by toggle + keybind element)
----------------------------------------------------------------
local function makeKeyBox(parent, default, onSet)
	local kb = { Key = default, Value = default }
	local btn = new("TextButton", {
		AutoButtonColor = false, Size = UDim2.fromOffset(74, 18), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
		Font = Theme.Font, TextSize = 12, TextColor3 = Theme.Text, Text = keyName(default), ZIndex = 2, Parent = parent,
	})
	corner(btn, 3)

	function kb:Set(k)
		kb.Key, kb.Value = k, k
		btn.Text = keyName(k)
		if onSet then onSet(k) end
	end

	btn.MouseButton1Click:Connect(function()
		if Library._listening then return end
		Library._listening = true
		btn.Text = "..."
		local c
		c = UIS.InputBegan:Connect(function(i)
			local k
			if i.UserInputType == Enum.UserInputType.Keyboard then
				if i.KeyCode ~= Enum.KeyCode.Escape then k = i.KeyCode end
			elseif i.UserInputType == Enum.UserInputType.MouseButton1
				or i.UserInputType == Enum.UserInputType.MouseButton2
				or i.UserInputType == Enum.UserInputType.MouseButton3 then
				k = i.UserInputType
			else
				return
			end
			c:Disconnect()
			task.defer(function() Library._listening = false end)
			kb:Set(k)
		end)
	end)
	return kb
end

local function addBind(win, bind)
	bind.Window = win
	table.insert(Library._binds, bind)
	table.insert(win.Binds, bind)
end

local function register(o, obj, typ)
	obj.Type = typ
	if o.Flag then Library.Options[o.Flag] = obj end
end

----------------------------------------------------------------
-- viewport
----------------------------------------------------------------
local function makeViewport(parent, o, win)
	o = o or {}
	local frame = new("ViewportFrame", {
		Size = o.Size or UDim2.new(1, 0, 0, o.Height or 160), BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		BorderSizePixel = 0, Ambient = Color3.fromRGB(190, 190, 190), LightColor = Color3.fromRGB(255, 255, 255),
		Parent = parent,
	})
	corner(frame, 4)
	stroke(frame)
	local cam = new("Camera", { FieldOfView = o.FOV or 50, Parent = frame })
	frame.CurrentCamera = cam
	local world = new("WorldModel", { Parent = frame })

	local vp = {
		Frame = frame, Yaw = o.Yaw or math.pi, Pitch = o.Pitch or math.rad(10),
		Distance = 8, MinDistance = 2, MaxDistance = 40, Center = Vector3.new(),
		AutoRotate = o.AutoRotate or false,
	}

	local function apply()
		cam.CFrame = CFrame.new(vp.Center) * CFrame.Angles(0, vp.Yaw, 0)
			* CFrame.Angles(-vp.Pitch, 0, 0) * CFrame.new(0, 0, vp.Distance)
	end

	function vp:SetModel(m)
		world:ClearAllChildren()
		if not m then return end
		local was = m.Archivable
		m.Archivable = true
		local c = m:Clone()
		m.Archivable = was
		if not c then return end
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then d:Destroy() end
		end
		c.Parent = world
		local cf, size
		if c:IsA("Model") then
			cf, size = c:GetBoundingBox()
		elseif c:IsA("BasePart") then
			cf, size = c.CFrame, c.Size
		else
			return
		end
		local radius = size.Magnitude / 2
		vp.Center = cf.Position
		vp.Distance = radius / math.sin(math.rad(cam.FieldOfView / 2))
		vp.MinDistance, vp.MaxDistance = radius * 0.6, radius * 6
		apply()
	end

	function vp:SetPlayer(p)
		if p and p.Character then vp:SetModel(p.Character) end
	end

	local dragging, last, hover = false, nil, false
	frame.InputBegan:Connect(function(i)
		if isPress(i) then dragging, last = true, i.Position end
	end)
	frame.MouseEnter:Connect(function() hover = true end)
	frame.MouseLeave:Connect(function() hover = false end)
	win:_connect(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
	win:_connect(UIS.InputChanged, function(i)
		if dragging and isMove(i) then
			local d = i.Position - last
			last = i.Position
			vp.Yaw = vp.Yaw - d.X * 0.01
			vp.Pitch = math.clamp(vp.Pitch + d.Y * 0.01, -1.2, 1.2)
		elseif hover and i.UserInputType == Enum.UserInputType.MouseWheel then
			vp.Distance = math.clamp(vp.Distance - i.Position.Z * (vp.MaxDistance * 0.05), vp.MinDistance, vp.MaxDistance)
		end
	end)
	win:_connect(RunService.RenderStepped, function(dt)
		if vp.AutoRotate and not dragging then vp.Yaw = vp.Yaw + dt * 0.8 end
		apply()
	end)

	if o.Model then
		vp:SetModel(o.Model)
	elseif o.Character then
		local lp = Players.LocalPlayer
		if lp.Character then vp:SetModel(lp.Character) end
		win:_connect(lp.CharacterAdded, function(ch) task.wait(1); vp:SetModel(ch) end)
	end
	apply()
	return vp
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
function Library.new(cfg)
	cfg = cfg or {}
	local self = setmetatable({
		Tabs = {}, Connections = {}, Popups = {}, Floating = {}, Binds = {},
		ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift, Visible = true,
	}, Window)

	self.Gui = makeGui(cfg.Name or "MatchaUI")
	local main = new("Frame", {
		Name = "Main", Size = cfg.Size or UDim2.fromOffset(640, 560), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = self.Gui,
	})
	corner(main, 4)
	stroke(main)
	self.Main = main

	-- title bar
	local titleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Active = true, Parent = main })
	local x = 10
	if cfg.Icon then
		new("ImageLabel", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(8, 5), BackgroundTransparency = 1, Image = cfg.Icon, Parent = titleBar })
		x = 30
	end
	local title = label(titleBar, "", { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x, 1, 0), RichText = true })
	bindAccent(function(c)
		local t = cfg.Title or "MatchaUI"
		if cfg.Subtitle then
			t = string.format('%s - <font color="#%s">%s</font>', t, c:ToHex(), cfg.Subtitle)
		end
		title.Text = t
	end)
	makeDraggable(titleBar, main, self)

	-- tab bar
	self.TabBar = new("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = main })
	list(self.TabBar, 2, Enum.FillDirection.Horizontal)
	pad(self.TabBar, 6, 0, 6, 0)
	new("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = main })

	self.Body = new("Frame", { Position = UDim2.fromOffset(8, 58), Size = UDim2.new(1, -16, 1, -66), BackgroundTransparency = 1, Parent = main })

	self:_connect(UIS.InputBegan, function(i, gp)
		if gp or Library._listening then return end
		if i.KeyCode == self.ToggleKey then self:Toggle() end
	end)

	return self
end

function Window:_connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self.Connections, c)
	return c
end

function Window:ClosePopups()
	for _, p in ipairs(self.Popups) do p.Visible = false end
end

function Window:SetVisible(v)
	self.Visible = v
	self.Main.Visible = v
	for _, f in ipairs(self.Floating) do f.Visible = v end
	if not v then self:ClosePopups() end
end

function Window:Toggle() self:SetVisible(not self.Visible) end

function Window:Destroy()
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	for _, b in ipairs(self.Binds) do
		local idx = table.find(Library._binds, b)
		if idx then table.remove(Library._binds, idx) end
	end
	self.Gui:Destroy()
end

function Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		local on = t == tab
		t.Page.Visible = on
		t.Underline.Visible = on
		tween(t.Button, { TextColor3 = on and Theme.Text or Theme.Dim })
	end
	self.Current = tab
	self:ClosePopups()
end

function Window:AddTab(name)
	local tab = setmetatable({ Window = self, Name = name, Count = { Left = 0, Right = 0 } }, Tab)

	tab.Button = new("TextButton", {
		AutoButtonColor = false, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1, Text = name, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Dim,
		LayoutOrder = #self.Tabs + 1, Parent = self.TabBar,
	})
	pad(tab.Button, 8, 0, 8, 0)
	tab.Underline = new("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BorderSizePixel = 0, Visible = false, Parent = tab.Button })
	bindAccent(function(c) tab.Underline.BackgroundColor3 = c end)

	tab.Page = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Body })

	local function column(pos, size)
		local sf = new("ScrollingFrame", {
			Position = pos, Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = tab.Page,
		})
		bindAccent(function(c) sf.ScrollBarImageColor3 = c end)
		list(sf, 8)
		pad(sf, 0, 0, 4, 0)
		return sf
	end
	tab.Left  = column(UDim2.new(0, 0, 0, 0),   UDim2.new(0.5, -4, 1, 0))
	tab.Right = column(UDim2.new(0.5, 4, 0, 0), UDim2.new(0.5, -4, 1, 0))

	tab.Button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then self:SelectTab(tab) end
	return tab
end

function Window:AddFloatingViewport(o)
	o = o or {}
	local w, h = o.Width or 220, o.Height or 240
	local f = new("Frame", {
		Size = UDim2.fromOffset(w, h + 24), Position = o.Position or UDim2.new(0.5, 340, 0.5, -h / 2),
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Visible = self.Visible, Parent = self.Gui,
	})
	corner(f, 4)
	stroke(f)
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Active = true, Parent = f })
	label(bar, o.Title or "Viewport", { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -8, 1, 0) })
	makeDraggable(bar, f, self)
	local holder = new("Frame", { Position = UDim2.fromOffset(6, 24), Size = UDim2.new(1, -12, 1, -30), BackgroundTransparency = 1, Parent = f })
	local vp = makeViewport(holder, { Size = UDim2.fromScale(1, 1), Model = o.Model, Character = o.Character, AutoRotate = o.AutoRotate }, self)
	vp.Window = f
	table.insert(self.Floating, f)
	return vp
end

----------------------------------------------------------------
-- Tab / Section
----------------------------------------------------------------
function Tab:AddSection(name, side)
	if side ~= "Left" and side ~= "Right" then
		side = (self.Count.Left <= self.Count.Right) and "Left" or "Right"
	end
	self.Count[side] = self.Count[side] + 1

	local sec = setmetatable({ Window = self.Window, _n = 0 }, Section)
	sec.Frame = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0, Parent = self[side],
	})
	corner(sec.Frame, 4)
	stroke(sec.Frame)
	pad(sec.Frame, 8)
	list(sec.Frame, 6)
	label(sec.Frame, name or "Section", { Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 0 })
	return sec
end

function Section:_order()
	self._n = self._n + 1
	return self._n
end

function Section:_row(h)
	return new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = self:_order(), Parent = self.Frame })
end

-- Toggle -------------------------------------------------------
function Section:AddToggle(o)
	o = o or {}
	local cb = o.Callback or function() end
	local state = o.Default or false
	local hasKey = o.Keybind ~= nil and o.Keybind ~= false
	local obj = { Value = state }

	local row = self:_row(20)
	local circle = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Parent = row })
	corner(circle, 8)
	local lbl = label(row, o.Name or "Toggle", { Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -24, 1, 0), TextColor3 = Theme.Dim })
	local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, hasKey and -84 or 0, 1, 0), Parent = row })

	local function paint()
		tween(circle, { BackgroundColor3 = state and Theme.Accent or Theme.Element })
		tween(lbl, { TextColor3 = state and Theme.Text or Theme.Dim })
	end
	bindAccent(function() paint() end)

	function obj:Set(v, silent)
		state = v and true or false
		obj.Value = state
		paint()
		if not silent then cb(state) end
	end
	function obj:Get() return state end
	hit.MouseButton1Click:Connect(function() obj:Set(not state) end)
	obj:Set(state, true)

	if hasKey then
		local kb = makeKeyBox(row, typeof(o.Keybind) == "EnumItem" and o.Keybind or nil)
		addBind(self.Window, { Get = function() return kb.Key end, Down = function() obj:Set(not state) end })
		obj.Keybind = kb
		if o.Flag then Library.Options[o.Flag .. "_key"] = setmetatable({ Type = "Keybind" }, { __index = kb, __newindex = kb }) end
	end
	register(o, obj, "Toggle")
	return obj
end

-- Slider -------------------------------------------------------
function Section:AddSlider(o)
	o = o or {}
	local min, max, dec = o.Min or 0, o.Max or 100, o.Decimals or 0
	local value = math.clamp(o.Default or min, min, max)
	local cb = o.Callback or function() end
	local obj = { Value = value }

	local holder = self:_row(38)
	label(holder, o.Name or "Slider", { Size = UDim2.new(1, 0, 0, 14) })
	local bar = new("TextButton", { AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 19), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, ClipsDescendants = true, Parent = holder })
	corner(bar, 9)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar })
	corner(fill, 9)
	bindAccent(function(c) fill.BackgroundColor3 = c end)
	local val = label(bar, "", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 12, TextStrokeTransparency = 0.6, ZIndex = 2 })

	local fmt = "%." .. dec .. "f"
	local function render()
		local denom = (max - min) == 0 and 1 or (max - min)
		fill.Size = UDim2.fromScale((value - min) / denom, 1)
		val.Text = string.format(fmt .. "/" .. fmt, value, max)
	end
	function obj:Set(v, silent)
		local m = 10 ^ dec
		value = math.clamp(math.floor(v * m + 0.5) / m, min, max)
		obj.Value = value
		render()
		if not silent then cb(value) end
	end
	function obj:Get() return value end

	local dragging = false
	local function fromX(x)
		local r = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local nv = min + (max - min) * r
		local m = 10 ^ dec
		nv = math.floor(nv * m + 0.5) / m
		if nv ~= value then obj:Set(nv) end
	end
	bar.InputBegan:Connect(function(i) if isPress(i) then dragging = true; fromX(i.Position.X) end end)
	self.Window:_connect(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
	self.Window:_connect(UIS.InputChanged, function(i) if dragging and isMove(i) then fromX(i.Position.X) end end)

	render()
	register(o, obj, "Slider")
	return obj
end

-- Dropdown -----------------------------------------------------
function Section:AddDropdown(o)
	o = o or {}
	local items, multi = o.Items or {}, o.Multi
	local cb = o.Callback or function() end
	local selected, single = {}, nil
	if multi then
		for _, v in ipairs(o.Default or {}) do selected[v] = true end
	else
		single = o.Default or items[1]
	end
	local obj = {}

	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = self:_order(), Parent = self.Frame })
	list(holder, 3)
	label(holder, o.Name or "Dropdown", { Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1 })
	local btn = new("TextButton", { AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Text = "", LayoutOrder = 2, Parent = holder })
	corner(btn, 3)
	local cur = label(btn, "", { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -28, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	label(btn, "▼", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -22, 0, 0), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 10, TextColor3 = Theme.Text })
	local drop = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Visible = false, LayoutOrder = 3, Parent = holder })
	corner(drop, 3)
	list(drop, 0)

	local function getList()
		local out = {}
		for _, v in ipairs(items) do if selected[v] then table.insert(out, v) end end
		return out
	end
	local function refresh()
		if multi then
			local l = getList()
			cur.Text = #l > 0 and table.concat(l, ", ") or "None"
			obj.Value = l
		else
			cur.Text = tostring(single)
			obj.Value = single
		end
		for _, c in ipairs(drop:GetChildren()) do
			if c:IsA("TextButton") then
				local on = multi and selected[c.Name] or (not multi and single == c.Name)
				c.TextColor3 = on and Theme.Accent or Theme.Text
			end
		end
	end
	local function build()
		for _, c in ipairs(drop:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for idx, item in ipairs(items) do
			local b = new("TextButton", { Name = item, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = item, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = idx, Parent = drop })
			pad(b, 8, 0, 0, 0)
			b.MouseButton1Click:Connect(function()
				if multi then
					selected[item] = not selected[item] or nil
					refresh()
					cb(obj.Value)
				else
					single = item
					drop.Visible = false
					refresh()
					cb(single)
				end
			end)
		end
		refresh()
	end

	function obj:Set(v, silent)
		if multi then
			selected = {}
			for _, x in ipairs(v or {}) do selected[x] = true end
		else
			single = v
		end
		refresh()
		if not silent then cb(obj.Value) end
	end
	function obj:Get() return obj.Value end
	function obj:SetItems(newItems)
		items = newItems
		build()
	end
	btn.MouseButton1Click:Connect(function() drop.Visible = not drop.Visible end)
	build()
	register(o, obj, "Dropdown")
	return obj
end

-- Keybind ------------------------------------------------------
function Section:AddKeybind(o)
	o = o or {}
	local cb = o.Callback or function() end
	local mode = o.Mode or "Toggle" -- Toggle | Hold | Press
	local state = false
	local obj = {}

	local row = self:_row(20)
	label(row, o.Name or "Keybind", { Size = UDim2.new(1, -80, 1, 0) })
	local kb = makeKeyBox(row, o.Default, function(k) obj.Value = k end)
	obj.Value = o.Default
	function obj:Set(k) kb:Set(k) end
	function obj:Get() return kb.Key end
	function obj:State() return state end

	addBind(self.Window, {
		Get = function() return kb.Key end,
		Down = function()
			if mode == "Hold" then state = true; cb(true)
			elseif mode == "Toggle" then state = not state; cb(state)
			else cb() end
		end,
		Up = function() if mode == "Hold" then state = false; cb(false) end end,
	})
	register(o, obj, "Keybind")
	return obj
end

-- Color picker -------------------------------------------------
function Section:AddColorPicker(o)
	o = o or {}
	local cb = o.Callback or function() end
	local color = o.Default or Color3.new(1, 1, 1)
	local h, s, v = color:ToHSV()
	local obj = { Value = color }
	local win = self.Window

	local row = self:_row(20)
	label(row, o.Name or "Color", { Size = UDim2.new(1, -40, 1, 0) })
	local swatch = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(30, 14), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = row })
	corner(swatch, 3)
	stroke(swatch)

	local pop = new("Frame", { Size = UDim2.fromOffset(166, 164), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Visible = false, ZIndex = 50, Parent = win.Gui })
	corner(pop, 4)
	stroke(pop)
	table.insert(win.Popups, pop)

	local sv = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(150, 120), BorderSizePixel = 0, Active = true, Parent = pop })
	corner(sv, 3)
	local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv })
	corner(white, 3)
	new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
	local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv })
	corner(black, 3)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
	local svCur = new("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = sv })
	corner(svCur, 4)
	stroke(svCur, Color3.new(1, 1, 1))

	local hue = new("Frame", { Position = UDim2.fromOffset(8, 138), Size = UDim2.fromOffset(150, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = true, Parent = pop })
	corner(hue, 3)
	local seq = {}
	for i = 0, 6 do table.insert(seq, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))) end
	new("UIGradient", { Color = ColorSequence.new(seq), Parent = hue })
	local hueCur = new("Frame", { Size = UDim2.fromOffset(3, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = hue })

	local function apply(silent)
		color = Color3.fromHSV(h, s, v)
		obj.Value = color
		swatch.BackgroundColor3 = color
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCur.Position = UDim2.fromScale(s, 1 - v)
		hueCur.Position = UDim2.fromScale(h, 0.5)
		if not silent then cb(color) end
	end
	function obj:Set(c, silent)
		h, s, v = c:ToHSV()
		apply(silent)
	end
	function obj:Get() return color end

	local dragSV, dragH = false, false
	local function updSV(p)
		s = math.clamp((p.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
		v = 1 - math.clamp((p.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
		apply()
	end
	local function updH(p)
		h = math.clamp((p.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
		apply()
	end
	sv.InputBegan:Connect(function(i) if isPress(i) then dragSV = true; updSV(i.Position) end end)
	hue.InputBegan:Connect(function(i) if isPress(i) then dragH = true; updH(i.Position) end end)
	win:_connect(UIS.InputEnded, function(i) if isPress(i) then dragSV, dragH = false, false end end)
	win:_connect(UIS.InputChanged, function(i)
		if not isMove(i) then return end
		if dragSV then updSV(i.Position) elseif dragH then updH(i.Position) end
	end)

	swatch.MouseButton1Click:Connect(function()
		local open = not pop.Visible
		win:ClosePopups()
		if open then
			pop.Position = UDim2.fromOffset(swatch.AbsolutePosition.X + 30 - 166, swatch.AbsolutePosition.Y + 18)
			pop.Visible = true
		end
	end)

	apply(true)
	register(o, obj, "ColorPicker")
	return obj
end

-- Button / Textbox / Label / Divider ---------------------------
function Section:AddButton(o)
	o = o or {}
	local cb = o.Callback or function() end
	local btn = new("TextButton", { AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Text = o.Name or "Button", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, LayoutOrder = self:_order(), Parent = self.Frame })
	corner(btn, 3)
	btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Color3.fromRGB(48, 48, 48) }) end)
	btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = Theme.Element }) end)
	btn.MouseButton1Click:Connect(function() cb() end)
	return btn
end

function Section:AddTextbox(o)
	o = o or {}
	local cb = o.Callback or function() end
	local obj = { Value = o.Default or "" }
	local holder = self:_row(40)
	label(holder, o.Name or "Textbox", { Size = UDim2.new(1, 0, 0, 14) })
	local box = new("TextBox", { Position = UDim2.fromOffset(0, 17), Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Text = obj.Value, PlaceholderText = o.Placeholder or "", PlaceholderColor3 = Theme.Dim, ClearTextOnFocus = false, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })
	corner(box, 3)
	pad(box, 8, 0, 8, 0)
	box.FocusLost:Connect(function() obj.Value = box.Text; cb(box.Text) end)
	function obj:Set(t) box.Text = t; obj.Value = t end
	function obj:Get() return box.Text end
	register(o, obj, "Textbox")
	return obj
end

function Section:AddLabel(text)
	local l = label(self.Frame, text, { Size = UDim2.new(1, 0, 0, 16), TextColor3 = Theme.Dim, LayoutOrder = self:_order() })
	return { Set = function(_, t) l.Text = t end }
end

function Section:AddDivider()
	return new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, LayoutOrder = self:_order(), Parent = self.Frame })
end

function Section:AddViewport(o)
	local vp = makeViewport(self.Frame, o, self.Window)
	vp.Frame.LayoutOrder = self:_order()
	return vp
end

----------------------------------------------------------------
-- Notifications
----------------------------------------------------------------
function Library:Notify(msg, dur)
	if not Library._nHolder then
		local g = makeGui("MatchaNotify")
		Library._nHolder = new("Frame", { Size = UDim2.new(0, 240, 1, -20), Position = UDim2.new(1, -250, 0, 10), BackgroundTransparency = 1, Parent = g })
		new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Library._nHolder })
	end
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = Library._nHolder })
	corner(f, 4)
	stroke(f)
	new("Frame", { Size = UDim2.new(0, 2, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = f })
	label(f, tostring(msg), { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -18, 1, 0), TextSize = 12 })
	task.delay(dur or 3, function() f:Destroy() end)
end

----------------------------------------------------------------
-- Config save / load
----------------------------------------------------------------
local function serialize(o)
	local v = o.Value
	if o.Type == "ColorPicker" then return { v.R, v.G, v.B } end
	if o.Type == "Keybind" then return v and tostring(v) or "" end
	return v
end

local function deserialize(o, v)
	if o.Type == "ColorPicker" then o:Set(Color3.new(v[1], v[2], v[3]))
	elseif o.Type == "Keybind" then o:Set(parseKey(v))
	else o:Set(v) end
end

function Library:SaveConfig(name)
	local data = {}
	for flag, o in pairs(Library.Options) do data[flag] = serialize(o) end
	if makefolder and isfolder and not isfolder(Library.ConfigFolder) then makefolder(Library.ConfigFolder) end
	if writefile then
		writefile(Library.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
		return true
	end
	return false
end

function Library:LoadConfig(name)
	local path = Library.ConfigFolder .. "/" .. name .. ".json"
	if not (isfile and readfile and isfile(path)) then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok then return false end
	for flag, v in pairs(data) do
		local o = Library.Options[flag]
		if o then pcall(deserialize, o, v) end
	end
	return true
end

function Library:ListConfigs()
	local out = {}
	if listfiles and isfolder and isfolder(Library.ConfigFolder) then
		for _, f in ipairs(listfiles(Library.ConfigFolder)) do
			local n = f:match("([^/\\]+)%.json$")
			if n then table.insert(out, n) end
		end
	end
	return out
end

----------------------------------------------------------------
-- Key system
-- Validate(key) -> boolean, message   (do the real check on YOUR server)
-- Yields until a valid key is entered, then returns true (false if closed).
----------------------------------------------------------------
function Library:KeySystem(o)
	o = o or {}
	local fileName = o.FileName or "matchaui_key.txt"
	local onSuccess = o.Callback or function() end

	local function check(key)
		local ok, res, msg = pcall(o.Validate or function() return false, "No validator set" end, key)
		if not ok then return false, "Validation error" end
		return res and true or false, msg
	end

	if o.SaveKey ~= false and isfile and readfile then
		local ok, saved = pcall(function() if isfile(fileName) then return readfile(fileName) end end)
		if ok and saved and saved ~= "" and check(saved) then
			onSuccess(saved)
			return true
		end
	end

	local gui = makeGui("MatchaKeySystem")
	local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = gui })
	local box = new("Frame", { Size = UDim2.fromOffset(340, 176), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = dim })
	corner(box, 4)
	stroke(box)

	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Active = true, Parent = box })
	local title = label(bar, "", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -40, 1, 0), RichText = true })
	bindAccent(function(c)
		title.Text = string.format('%s - <font color="#%s">%s</font>', o.Title or "Key System", c:ToHex(), o.Subtitle or "authentication")
	end)
	local close = new("TextButton", { Text = "x", Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Dim, BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -26, 0, 0), Parent = bar })
	do -- drag
		local drag, sp, sf = false, nil, nil
		bar.InputBegan:Connect(function(i) if isPress(i) then drag, sp, sf = true, i.Position, box.Position end end)
		UIS.InputEnded:Connect(function(i) if isPress(i) then drag = false end end)
		UIS.InputChanged:Connect(function(i)
			if drag and isMove(i) then
				local d = i.Position - sp
				box.Position = UDim2.new(sf.X.Scale, sf.X.Offset + d.X, sf.Y.Scale, sf.Y.Offset + d.Y)
			end
		end)
	end

	label(box, o.Note or "Enter your key to continue", { Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 16), TextColor3 = Theme.Dim, TextSize = 12 })
	local input = new("TextBox", { Position = UDim2.fromOffset(12, 54), Size = UDim2.new(1, -24, 0, 28), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Text = "", PlaceholderText = "key...", PlaceholderColor3 = Theme.Dim, ClearTextOnFocus = false, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = box })
	corner(input, 3)
	pad(input, 8, 0, 8, 0)

	local function button(text, x, w)
		local b = new("TextButton", { AutoButtonColor = false, Position = UDim2.fromOffset(x, 92), Size = UDim2.new(0.5, -17, 0, 26), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Text = text, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, Parent = box })
		corner(b, 3)
		return b
	end
	local redeem = button("Redeem", 12)
	redeem.Position = UDim2.new(0, 12, 0, 92)
	local getKey = button("Get Key", 0)
	getKey.Position = UDim2.new(0.5, 5, 0, 92)
	bindAccent(function(c) redeem.BackgroundColor3 = c; redeem.TextColor3 = Color3.fromRGB(20, 20, 20) end)

	local status = label(box, "", { Position = UDim2.fromOffset(12, 130), Size = UDim2.new(1, -24, 0, 30), TextSize = 12, TextColor3 = Theme.Dim, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })

	local done = Instance.new("BindableEvent")
	local busy = false

	getKey.MouseButton1Click:Connect(function()
		if setclipboard then setclipboard(tostring(o.GetKeyLink or "")) end
		getKey.Text = "Copied!"
		task.delay(1.4, function() if getKey.Parent then getKey.Text = "Get Key" end end)
	end)

	local function submit()
		if busy then return end
		local key = input.Text:gsub("%s+", "")
		if key == "" then return end
		busy = true
		redeem.Text = "Checking..."
		task.spawn(function()
			local ok, msg = check(key)
			redeem.Text = "Redeem"
			busy = false
			if ok then
				status.TextColor3 = Theme.Accent
				status.Text = msg or "Key accepted"
				if o.SaveKey ~= false and writefile then pcall(writefile, fileName, key) end
				task.wait(0.6)
				gui:Destroy()
				onSuccess(key)
				done:Fire(true)
			else
				status.TextColor3 = Color3.fromRGB(235, 90, 90)
				status.Text = msg or "Invalid key"
			end
		end)
	end
	redeem.MouseButton1Click:Connect(submit)
	input.FocusLost:Connect(function(enter) if enter then submit() end end)
	close.MouseButton1Click:Connect(function() gui:Destroy(); done:Fire(false) end)

	return done.Event:Wait()
end

return Library
