--[[
    sqservices.me UI Library
    Version 4.0
    - Transparent glass look (sidebar + content panel, matches the Crosshair screenshot)
    - "S" logo next to the title, title shows "sqservices.me • <current tab>"
    - Info pill in the top bar: time + your IP (click it to hide the IP)
    - Same hide button (–), floating reopen button (☰) and RightShift toggle
    - Fully re-colorable at runtime: Window:SetAccent / SetBackground / SetTransparency
    - Tab:CreateColorPicker + Window:AddThemeTab() for in-UI color changing
    - ESP Preview panel with a 3D character model (ViewportFrame) like the video
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local Defaults = {
    Title = "sqservices.me",
    Logo = "S",
    LogoImage = nil,                       -- optional "rbxassetid://..." instead of the S
    Size = UDim2.new(0, 560, 0, 410),
    BackgroundColor = Color3.fromRGB(10, 13, 26),
    AccentColor = Color3.fromRGB(55, 115, 220),
    TextColor = Color3.fromRGB(225, 235, 255),
    SubTextColor = Color3.fromRGB(145, 160, 195),
    Transparency = 0.2,                    -- 0 = solid, 1 = invisible
    SidebarWidth = 134,
    CornerRadius = UDim.new(0, 14),
    ToggleKey = Enum.KeyCode.RightShift,
    ShowInfo = true,                       -- time + IP pill
    BackgroundImage = nil,
}

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function Tween(obj, props, time, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir = dir or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.28, style, dir), props)
    t:Play()
    return t
end

local function Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function Corner(parent, radius)
    return Create("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function Mix(a, b, t)
    return a:Lerp(b, t)
end

local function IsPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function Hex(c)
    return string.format("#%02x%02x%02x",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5))
end

local function Escape(s)
    return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Fill color used by off-toggles / slider tracks / buttons (follows theme)
local function ElementColor(theme)
    return Mix(Mix(theme.Background, theme.Accent, 0.22), WHITE, 0.04)
end

-- Local-only: fetches YOUR public IP so you can see it in the bar. Never sent anywhere.
local function FetchIP()
    local attempts = {
        function() return game:HttpGet("https://api.ipify.org") end,
        function()
            local req = request or http_request or (syn and syn.request)
            if req then
                local res = req({Url = "https://api.ipify.org", Method = "GET"})
                return res and res.Body
            end
        end,
        function() return HttpService:GetAsync("https://api.ipify.org") end,
    }
    for _, fn in ipairs(attempts) do
        local ok, result = pcall(fn)
        if ok and type(result) == "string" then
            result = result:gsub("%s+", "")
            if result:match("^[%x%.:]+$") and #result >= 7 then
                return result
            end
        end
    end
    return nil
end

-------------------------------------------------
-- WINDOW
-------------------------------------------------
function Library:Bind(fn)
    table.insert(self._binds, fn)
    pcall(fn, self.Theme)
    return fn
end

function Library:Refresh()
    for _, fn in ipairs(self._binds) do
        pcall(fn, self.Theme)
    end
end

function Library:SetAccent(color)
    self.Theme.Accent = color
    self:Refresh()
end

function Library:SetBackground(color)
    self.Theme.Background = color
    self:Refresh()
end

function Library:SetTextColor(color)
    self.Theme.Text = color
    self:Refresh()
end

function Library:SetSubTextColor(color)
    self.Theme.SubText = color
    self:Refresh()
end

function Library:SetTransparency(value)
    self.Theme.Transparency = math.clamp(value, 0, 0.95)
    self:Refresh()
end

function Library:SetTheme(tbl)
    for k, v in pairs(tbl) do
        self.Theme[k] = v
    end
    self:Refresh()
end

function Library:Destroy()
    for _, c in ipairs(self._connections) do
        pcall(function() c:Disconnect() end)
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function Library:CreateWindow(config)
    config = config or {}
    for key, value in pairs(Defaults) do
        if config[key] == nil then
            config[key] = value
        end
    end

    local Window = setmetatable({}, Library)
    Window.Config = config
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.IsHidden = false
    Window.IPHidden = false
    Window.IP = nil
    Window._binds = {}
    Window._connections = {}
    Window.Theme = {
        Background = config.BackgroundColor,
        Accent = config.AccentColor,
        Text = config.TextColor,
        SubText = config.SubTextColor,
        Transparency = config.Transparency,
    }

    local function Connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(Window._connections, c)
        return c
    end
    Window._Connect = Connect

    local ScreenGui = Create("ScreenGui", {
        Name = "sqservicesUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
    }, LocalPlayer:WaitForChild("PlayerGui"))

    -- Root moves/hides as one unit (holds Main + the optional ESP preview panel)
    local Root = Create("Frame", {
        Name = "Root",
        Size = config.Size,
        Position = UDim2.new(0.5, -config.Size.X.Offset / 2, 0.5, -config.Size.Y.Offset / 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, ScreenGui)

    local Main = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = config.BackgroundColor,
        BackgroundTransparency = Window.Theme.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, Root)
    Create("UICorner", {CornerRadius = config.CornerRadius}, Main)
    local MainStroke = Stroke(Main, config.AccentColor, 1.3, 0.45)

    -- Soft blend layer
    local Blend = Create("Frame", {
        Name = "BlendLayer",
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        ZIndex = 0,
    }, Main)
    Create("UICorner", {CornerRadius = config.CornerRadius}, Blend)
    Create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(1, 0.9),
        }),
    }, Blend)

    if config.BackgroundImage and config.BackgroundImage ~= "" then
        local Bg = Create("ImageLabel", {
            Name = "BackgroundImage",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = config.BackgroundImage,
            ScaleType = Enum.ScaleType.Crop,
            ImageTransparency = 0.78,
            ZIndex = 0,
        }, Main)
        Create("UICorner", {CornerRadius = config.CornerRadius}, Bg)
    end

    -- Top bar
    local TopBar = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Active = true,
        ZIndex = 5,
    }, Main)

    -- "S" logo
    local Logo = Create("Frame", {
        Name = "Logo",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 14, 0.5, -12),
        BorderSizePixel = 0,
        ZIndex = 6,
    }, TopBar)
    Corner(Logo, 7)
    if config.LogoImage then
        Create("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = config.LogoImage,
            ZIndex = 7,
        }, Logo)
    else
        Create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = config.Logo,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = WHITE,
            ZIndex = 7,
        }, Logo)
    end

    -- Title:  sqservices.me • Tab
    local Title = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 260, 1, 0),
        Position = UDim2.new(0, 46, 0, 0),
        BackgroundTransparency = 1,
        RichText = true,
        Font = Enum.Font.GothamMedium,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, TopBar)

    -- Info pill (time + IP)
    local InfoBtn = Create("TextButton", {
        Name = "Info",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -52, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Text = "--:--:--  •  loading...",
        Visible = config.ShowInfo,
        ZIndex = 6,
    }, TopBar)
    Corner(InfoBtn, 7)
    Create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, InfoBtn)

    local function UpdateInfo()
        local t = os.date("*t")
        local ip = Window.IPHidden and "IP hidden" or (Window.IP or "loading...")
        InfoBtn.Text = string.format("%02d:%02d:%02d  •  %s", t.hour, t.min, t.sec, ip)
    end
    InfoBtn.MouseButton1Click:Connect(function()
        Window.IPHidden = not Window.IPHidden
        UpdateInfo()
    end)

    task.spawn(function()
        while ScreenGui.Parent do
            UpdateInfo()
            task.wait(1)
        end
    end)
    task.spawn(function()
        Window.IP = FetchIP() or "unknown"
        UpdateInfo()
    end)

    -- Hide (minimize) button — same as before
    local MinimizeBtn = Create("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 32, 0, 28),
        Position = UDim2.new(1, -42, 0.5, -14),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Text = "–",
        ZIndex = 6,
    }, TopBar)
    Corner(MinimizeBtn, 8)

    local TopDivider = Create("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 1, -1),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
    }, TopBar)

    -- Content
    local Content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        ZIndex = 2,
    }, Main)

    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, config.SidebarWidth, 1, 0),
        BackgroundTransparency = 1,
    }, Content)
    Create("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 8),
    }, Sidebar)

    local SideDivider = Create("Frame", {
        Name = "SideDivider",
        Size = UDim2.new(0, 1, 1, -16),
        Position = UDim2.new(0, config.SidebarWidth, 0, 8),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, Content)

    local RightPanel = Create("Frame", {
        Name = "RightPanel",
        Size = UDim2.new(1, -(config.SidebarWidth + 14), 1, 0),
        Position = UDim2.new(0, config.SidebarWidth + 14, 0, 0),
        BackgroundTransparency = 1,
    }, Content)

    local TabTitle = Create("TextLabel", {
        Name = "TabTitle",
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.new(0, 8, 0, 10),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, RightPanel)

    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -16, 1, -50),
        Position = UDim2.new(0, 8, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, RightPanel)

    Window.Root = Root
    Window.Main = Main
    Window.Sidebar = Sidebar
    Window.TabTitle = TabTitle
    Window.TabContainer = TabContainer
    Window.ScreenGui = ScreenGui

    -- Floating reopen button
    local OpenBtn = Create("TextButton", {
        Name = "OpenUI",
        Size = UDim2.new(0, 46, 0, 46),
        Position = UDim2.new(1, -68, 1, -68),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        Text = "☰",
        Visible = false,
        ZIndex = 100,
    }, ScreenGui)
    Corner(OpenBtn, 12)
    local OpenStroke = Stroke(OpenBtn, config.AccentColor, 1.4, 0.35)

    -- Theme bindings for everything above
    local function UpdateTitle()
        local t = Window.Theme
        local text = Escape(config.Title)
        if Window.CurrentTab then
            text = text .. string.format('  <font color="%s">•  %s</font>', Hex(t.SubText), Escape(Window.CurrentTab.Name))
        end
        Title.Text = text
    end

    Window:Bind(function(t)
        Main.BackgroundColor3 = t.Background
        if not Window.IsHidden then
            Main.BackgroundTransparency = t.Transparency
        end
        MainStroke.Color = Mix(t.Background, t.Accent, 0.5)
        Blend.BackgroundColor3 = Mix(t.Background, t.Accent, 0.16)
        Logo.BackgroundColor3 = t.Accent
        UpdateTitle()
        InfoBtn.BackgroundColor3 = ElementColor(t)
        InfoBtn.TextColor3 = t.SubText
        MinimizeBtn.BackgroundColor3 = ElementColor(t)
        MinimizeBtn.TextColor3 = t.Text
        TopDivider.BackgroundColor3 = Mix(t.Background, t.Accent, 0.6)
        SideDivider.BackgroundColor3 = Mix(t.Background, t.Accent, 0.6)
        TabTitle.TextColor3 = t.Text
        OpenBtn.BackgroundColor3 = Mix(t.Background, t.Accent, 0.2)
        OpenBtn.TextColor3 = t.Text
        OpenStroke.Color = t.Accent
    end)

    -- Hide / Show
    local function HideUI()
        if Window.IsHidden then return end
        Window.IsHidden = true
        Tween(Main, {Size = UDim2.fromScale(0.92, 0.92), BackgroundTransparency = 0.6}, 0.22)
        task.delay(0.14, function()
            if not Window.IsHidden then return end
            Root.Visible = false
            OpenBtn.Visible = true
            OpenBtn.BackgroundTransparency = 1
            OpenBtn.TextTransparency = 1
            Tween(OpenBtn, {BackgroundTransparency = 0.2, TextTransparency = 0}, 0.2)
        end)
    end

    local function ShowUI()
        if not Window.IsHidden then return end
        Window.IsHidden = false
        OpenBtn.Visible = false
        Root.Visible = true
        Main.BackgroundTransparency = 0.6
        Main.Size = UDim2.fromScale(0.92, 0.92)
        Tween(Main, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = Window.Theme.Transparency}, 0.3, Enum.EasingStyle.Back)
    end

    Window.Hide = HideUI
    Window.Show = ShowUI
    function Window:Toggle()
        if Window.IsHidden then ShowUI() else HideUI() end
    end

    MinimizeBtn.MouseEnter:Connect(function() Tween(MinimizeBtn, {BackgroundTransparency = 0.15}, 0.15) end)
    MinimizeBtn.MouseLeave:Connect(function() Tween(MinimizeBtn, {BackgroundTransparency = 0.4}, 0.15) end)
    MinimizeBtn.MouseButton1Click:Connect(HideUI)
    OpenBtn.MouseButton1Click:Connect(ShowUI)

    Connect(UserInputService.InputBegan, function(input, gp)
        if gp then return end
        if input.KeyCode == config.ToggleKey then
            Window:Toggle()
        end
    end)

    -- Dragging (moves Root so the ESP preview follows)
    local Dragging, DragStart, StartPos = false, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if IsPress(input) then
            Dragging = true
            DragStart = input.Position
            StartPos = Root.Position
        end
    end)
    TopBar.InputEnded:Connect(function(input)
        if IsPress(input) then Dragging = false end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if Dragging and IsMove(input) then
            local delta = input.Position - DragStart
            Root.Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Open animation
    Main.BackgroundTransparency = 1
    Main.Size = UDim2.fromScale(0.86, 0.86)
    Tween(Main, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = Window.Theme.Transparency}, 0.4, Enum.EasingStyle.Back)

    print("[sqservices.me] UI Library loaded (v4.0)")
    return Window
end

-------------------------------------------------
-- ELEMENT BUILDERS (shared)
-------------------------------------------------
local function BuildSlider(window, parent, o)
    local name = o.Name or "Slider"
    local min, max = o.Min or 0, o.Max or 100
    local inc = o.Increment or 1
    local suffix = o.Suffix or ""
    local callback = o.Callback or function() end
    local value = math.clamp(o.Default or min, min, max)

    local Holder = Create("Frame", {Name = name, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1}, parent)
    local Label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Holder)
    local Track = Create("Frame", {
        Size = UDim2.new(1, -14, 0, 4),
        Position = UDim2.new(0, 7, 0, 29),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, Holder)
    Corner(Track, 2)
    local Fill = Create("Frame", {Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0}, Track)
    Corner(Fill, 2)
    local Knob = Create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(235, 242, 255),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, Track)
    Corner(Knob, 7)
    local Hit = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        Active = true,
        ZIndex = 3,
    }, Holder)

    local function Render(animated)
        local pct = (max - min) == 0 and 0 or (value - min) / (max - min)
        Label.Text = name .. "  •  " .. tostring(value) .. suffix
        if animated then
            Tween(Fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.08)
            Tween(Knob, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.08)
        else
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            Knob.Position = UDim2.new(pct, 0, 0.5, 0)
        end
    end

    local function Snap(v)
        v = math.floor((v - min) / inc + 0.5) * inc + min
        v = math.floor(v * 1000 + 0.5) / 1000
        return math.clamp(v, min, max)
    end

    local function SetValue(v, silent)
        value = Snap(v)
        Render(false)
        if not silent then callback(value) end
    end

    local Dragging = false
    local function Update(input)
        local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
        local new = Snap(min + (max - min) * rel)
        if new ~= value then
            value = new
            Render(true)
            callback(value)
        end
    end

    Hit.InputBegan:Connect(function(input)
        if IsPress(input) then
            Dragging = true
            Update(input)
        end
    end)
    window._Connect(UserInputService.InputChanged, function(input)
        if Dragging and IsMove(input) then Update(input) end
    end)
    window._Connect(UserInputService.InputEnded, function(input)
        if IsPress(input) then Dragging = false end
    end)

    window:Bind(function(t)
        Label.TextColor3 = t.SubText
        Track.BackgroundColor3 = ElementColor(t)
        Fill.BackgroundColor3 = t.Accent
    end)

    Render(false)
    return Holder, {
        Set = SetValue,
        Get = function() return value end,
    }
end

-------------------------------------------------
-- TABS
-------------------------------------------------
function Library:CreateTab(name)
    local Window = self
    local Tab = {Name = name, Window = Window}

    local Button = Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #Window.Tabs + 1,
    }, Window.Sidebar)
    Create("UIPadding", {PaddingLeft = UDim.new(0, 12)}, Button)
    Corner(Button, 8)

    local ContentFrame = Create("ScrollingFrame", {
        Name = name .. "_Content",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.35,
        Visible = false,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, Window.TabContainer)
    Create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, ContentFrame)
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 8),
    }, ContentFrame)

    Tab.Container = ContentFrame
    Tab.Button = Button

    Window:Bind(function(t)
        local selected = Window.CurrentTab == Tab
        Button.BackgroundColor3 = Mix(t.Background, t.Accent, 0.35)
        ContentFrame.ScrollBarImageColor3 = t.Accent
        Tween(Button, {
            BackgroundTransparency = selected and 0.3 or 1,
            TextColor3 = selected and t.Text or t.SubText,
        }, 0.2)
    end)

    Button.MouseEnter:Connect(function()
        if Window.CurrentTab ~= Tab then
            Tween(Button, {BackgroundTransparency = 0.65, TextColor3 = Window.Theme.Text}, 0.18)
        end
    end)
    Button.MouseLeave:Connect(function()
        if Window.CurrentTab ~= Tab then
            Tween(Button, {BackgroundTransparency = 1, TextColor3 = Window.Theme.SubText}, 0.18)
        end
    end)
    Button.MouseButton1Click:Connect(function()
        Window:SelectTab(Tab)
    end)

    table.insert(Window.Tabs, Tab)
    if #Window.Tabs == 1 then
        Window:SelectTab(Tab)
    end

    -- Section header
    function Tab:CreateSection(text)
        local Label = Create("TextLabel", {
            Name = "Section",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = string.upper(text or "Section"),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, self.Container)
        Window:Bind(function(t) Label.TextColor3 = t.SubText end)
        return Label
    end

    -- Label
    function Tab:CreateLabel(text)
        local Label = Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = text or "",
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, self.Container)
        Window:Bind(function(t) Label.TextColor3 = t.SubText end)
        return Label
    end

    -- Button
    function Tab:CreateButton(options)
        options = options or {}
        local callback = options.Callback or function() end
        local Btn = Create("TextButton", {
            Name = options.Name or "Button",
            Size = UDim2.new(0, options.Width or 132, 0, 30),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            Text = options.Name or "Button",
        }, self.Container)
        Corner(Btn, 8)
        local BtnStroke = Stroke(Btn, WHITE, 1, 0.5)
        Window:Bind(function(t)
            Btn.BackgroundColor3 = ElementColor(t)
            Btn.TextColor3 = t.Text
            BtnStroke.Color = Mix(t.Background, t.Accent, 0.6)
        end)
        Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundTransparency = 0.05}, 0.15) end)
        Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundTransparency = 0.25}, 0.15) end)
        Btn.MouseButton1Click:Connect(callback)
        return Btn
    end

    -- Toggle
    function Tab:CreateToggle(options)
        options = options or {}
        local name = options.Name or "Toggle"
        local callback = options.Callback or function() end
        local state = options.Default or false

        local Holder = Create("Frame", {Name = name, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1}, self.Container)
        local Label = Create("TextLabel", {
            Size = UDim2.new(1, -56, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, Holder)
        local Track = Create("Frame", {
            Name = "Track",
            Size = UDim2.new(0, 42, 0, 22),
            Position = UDim2.new(1, -50, 0.5, -11),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Active = true,
        }, Holder)
        Corner(Track, 11)
        local Knob = Create("Frame", {
            Name = "Knob",
            Size = UDim2.new(0, 16, 0, 16),
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(240, 245, 255),
            BorderSizePixel = 0,
        }, Track)
        Corner(Knob, 8)

        local function Paint(animated)
            local t = Window.Theme
            local color = state and t.Accent or Mix(ElementColor(t), WHITE, 0.06)
            local pos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            if animated then
                Tween(Track, {BackgroundColor3 = color}, 0.2)
                Tween(Knob, {Position = pos}, 0.2)
            else
                Track.BackgroundColor3 = color
                Knob.Position = pos
            end
        end
        Window:Bind(function(t)
            Label.TextColor3 = t.Text
            Paint(false)
        end)

        local function SetState(new, silent)
            state = new and true or false
            Paint(true)
            if not silent then callback(state) end
        end
        Track.InputBegan:Connect(function(input)
            if IsPress(input) then SetState(not state) end
        end)

        return Holder, {Set = SetState, Get = function() return state end}
    end

    -- Checkbox
    function Tab:CreateCheckbox(options)
        options = options or {}
        local name = options.Name or "Checkbox"
        local callback = options.Callback or function() end
        local state = options.Default or false

        local Holder = Create("Frame", {Name = name, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1}, self.Container)
        local Box = Create("Frame", {
            Name = "Box",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 0, 0.5, -10),
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            Active = true,
        }, Holder)
        Corner(Box, 5)
        local BoxStroke = Stroke(Box, WHITE, 1, 0.45)
        local Check = Create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = state and "✓" or "",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = WHITE,
        }, Box)
        local Label = Create("TextLabel", {
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 28, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, Holder)

        local function Paint(animated)
            local t = Window.Theme
            local color = state and t.Accent or ElementColor(t)
            if animated then Tween(Box, {BackgroundColor3 = color}, 0.15) else Box.BackgroundColor3 = color end
            Check.Text = state and "✓" or ""
        end
        Window:Bind(function(t)
            Label.TextColor3 = t.Text
            BoxStroke.Color = Mix(t.Background, t.Accent, 0.6)
            Paint(false)
        end)

        local function SetState(new, silent)
            state = new and true or false
            Paint(true)
            if not silent then callback(state) end
        end
        Box.InputBegan:Connect(function(input)
            if IsPress(input) then SetState(not state) end
        end)

        return Holder, {Set = SetState, Get = function() return state end}
    end

    -- Slider
    function Tab:CreateSlider(options)
        return BuildSlider(Window, self.Container, options or {})
    end

    -- Color picker (hue / saturation / brightness)
    function Tab:CreateColorPicker(options)
        options = options or {}
        local name = options.Name or "Color"
        local callback = options.Callback or function() end
        local color = options.Default or Window.Theme.Accent
        local h, s, v = color:ToHSV()
        local expanded = false
        local EXPANDED_H = 34 + 3 * 44 + 4

        local Holder = Create("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
        }, self.Container)

        local Header = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        }, Holder)
        local Label = Create("TextLabel", {
            Size = UDim2.new(1, -70, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, Header)
        local Swatch = Create("Frame", {
            Size = UDim2.new(0, 42, 0, 22),
            Position = UDim2.new(1, -50, 0.5, -11),
            BorderSizePixel = 0,
            BackgroundColor3 = color,
        }, Header)
        Corner(Swatch, 7)
        local SwatchStroke = Stroke(Swatch, WHITE, 1, 0.5)

        local Body = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 3 * 44),
            Position = UDim2.new(0, 0, 0, 34),
            BackgroundTransparency = 1,
        }, Holder)
        Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, Body)

        local function Apply(silent)
            color = Color3.fromHSV(h, s, v)
            Swatch.BackgroundColor3 = color
            if not silent then callback(color) end
        end

        local _, hueAPI = BuildSlider(Window, Body, {
            Name = "Hue", Min = 0, Max = 360, Default = math.floor(h * 360 + 0.5),
            Callback = function(val) h = val / 360; Apply() end,
        })
        local _, satAPI = BuildSlider(Window, Body, {
            Name = "Saturation", Min = 0, Max = 100, Default = math.floor(s * 100 + 0.5),
            Callback = function(val) s = val / 100; Apply() end,
        })
        local _, valAPI = BuildSlider(Window, Body, {
            Name = "Brightness", Min = 0, Max = 100, Default = math.floor(v * 100 + 0.5),
            Callback = function(val) v = val / 100; Apply() end,
        })

        Header.MouseButton1Click:Connect(function()
            expanded = not expanded
            Tween(Holder, {Size = UDim2.new(1, 0, 0, expanded and EXPANDED_H or 32)}, 0.25)
        end)

        Window:Bind(function(t)
            Label.TextColor3 = t.Text
            SwatchStroke.Color = Mix(t.Background, t.Accent, 0.6)
        end)

        return Holder, {
            Get = function() return color end,
            Set = function(c, silent)
                h, s, v = c:ToHSV()
                hueAPI.Set(math.floor(h * 360 + 0.5), true)
                satAPI.Set(math.floor(s * 100 + 0.5), true)
                valAPI.Set(math.floor(v * 100 + 0.5), true)
                Apply(silent)
            end,
        }
    end

    -- ESP preview shortcut
    function Tab:CreateESPPreview(options)
        return Window:CreateESPPreview(options)
    end

    return Tab
end

function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end
    local old = self.CurrentTab
    self.CurrentTab = tab
    if old then old.Container.Visible = false end

    tab.Container.Visible = true
    tab.Container.Position = UDim2.new(0, 0, 0, 8)
    Tween(tab.Container, {Position = UDim2.new(0, 0, 0, 0)}, 0.25)
    self.TabTitle.Text = tab.Name
    self:Refresh()
end

-- Ready-made "Settings" tab to recolor the whole UI
function Library:AddThemeTab(name)
    local tab = self:CreateTab(name or "Settings")
    tab:CreateSection("Theme")
    tab:CreateColorPicker({
        Name = "Accent Color",
        Default = self.Theme.Accent,
        Callback = function(c) self:SetAccent(c) end,
    })
    tab:CreateColorPicker({
        Name = "Background Color",
        Default = self.Theme.Background,
        Callback = function(c) self:SetBackground(c) end,
    })
    tab:CreateSlider({
        Name = "Transparency",
        Min = 0, Max = 80, Suffix = "%",
        Default = math.floor(self.Theme.Transparency * 100 + 0.5),
        Callback = function(val) self:SetTransparency(val / 100) end,
    })
    return tab
end

-------------------------------------------------
-- ESP PREVIEW (3D model in a ViewportFrame)
-------------------------------------------------
local function CloneCharacter(char)
    if not char then return nil end
    local old = char.Archivable
    char.Archivable = true
    local ok, clone = pcall(function() return char:Clone() end)
    char.Archivable = old
    if not ok or not clone then return nil end
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ForceField") or d:IsA("Humanoid") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored = true
        end
    end
    return clone
end

local function BuildDummy()
    local m = Instance.new("Model")
    m.Name = "PreviewDummy"
    local function part(n, size, pos, color)
        local p = Instance.new("Part")
        p.Name = n
        p.Size = size
        p.Position = pos
        p.Color = color
        p.Anchored = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = m
        return p
    end
    local skin = Color3.fromRGB(245, 205, 150)
    local shirt = Color3.fromRGB(40, 40, 48)
    local pants = Color3.fromRGB(25, 25, 30)
    local torso = part("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), shirt)
    part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), skin)
    part("LeftArm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), shirt)
    part("RightArm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), shirt)
    part("LeftLeg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), pants)
    part("RightLeg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), pants)
    m.PrimaryPart = torso
    return m
end

--[[
    Window:CreateESPPreview({
        Title = "ESP Preview",
        Side = "Right",              -- or "Left"
        Box = true, Name = true, Distance = true, Health = true,   -- starting states
        BoxColor / NameColor / DistanceColor / HealthColor = Color3 (optional)
        PlayerName = "kuna", DistanceText = "24m", HealthPercent = 100,
        Spin = false,                -- true = full rotation, false = gentle sway
        Model = player/character,    -- optional (default: your character)
        Callback = function(element, state) end,  -- fired when user taps an element
    })
    returns Preview with:
        Preview:Set("Box"|"Name"|"Distance"|"Health", bool, silent)
        Preview:Get(element)
        Preview:SetColor(element, Color3)
        Preview:SetModel(playerOrCharacter)    -- nil = your character
        Preview:SetNameText(text) / SetDistanceText(text) / SetHealthPercent(0-100)
        Preview:SetVisible(bool) / Preview:Destroy()
]]
function Library:CreateESPPreview(o)
    o = o or {}
    local Window = self
    local Preview = {}

    local PW, PH = 220, 330
    local SW, SH = PW - 24, PH - 64        -- stage size
    local FILL = 0.62                      -- model height as a fraction of the stage

    local states = {
        Box = o.Box ~= false,
        Name = o.Name ~= false,
        Distance = o.Distance ~= false,
        Health = o.Health ~= false,
    }
    local colors = {
        Box = o.BoxColor,
        Name = o.NameColor,
        Distance = o.DistanceColor,
        Health = o.HealthColor,
    }
    local healthPct = math.clamp(o.HealthPercent or 100, 0, 100)
    local callback = o.Callback or function() end

    local Panel = Create("Frame", {
        Name = "ESPPreview",
        Size = UDim2.new(0, PW, 0, PH),
        Position = (o.Side == "Left") and UDim2.new(0, -PW - 10, 0, 0) or UDim2.new(1, 10, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, Window.Root)
    Create("UICorner", {CornerRadius = Window.Config.CornerRadius}, Panel)
    local PanelStroke = Stroke(Panel, WHITE, 1.3, 0.45)

    local PTitle = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 14, 0, 12),
        BackgroundTransparency = 1,
        Text = o.Title or "ESP Preview",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Panel)
    local PSub = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.new(0, 14, 0, 30),
        BackgroundTransparency = 1,
        Text = "Tap an element to toggle it",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Panel)

    local Stage = Create("Frame", {
        Size = UDim2.new(0, SW, 0, SH),
        Position = UDim2.new(0, 12, 0, 52),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, Panel)
    Corner(Stage, 10)

    local Viewport = Create("ViewportFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Ambient = Color3.fromRGB(175, 175, 190),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = Vector3.new(-0.4, -0.6, 0.7),
    }, Stage)
    local Cam = Create("Camera", {FieldOfView = 30}, Viewport)
    Viewport.CurrentCamera = Cam

    -- Overlay elements ----------------------------------------------------
    local BoxBtn = Create("TextButton", {
        Name = "Box",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 100, 0, 160),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    }, Stage)
    local BoxStroke = Stroke(BoxBtn, WHITE, 1.5, 0)

    local HealthBtn = Create("TextButton", {
        Name = "Health",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 10, 0, 160),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    }, Stage)
    local HealthTrack = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = BLACK,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
    }, HealthBtn)
    local HealthFill = Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
    }, HealthTrack)

    local NameBtn = Create("TextButton", {
        Name = "Name",
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(0, 150, 0, 14),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = o.PlayerName or LocalPlayer.DisplayName,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextStrokeTransparency = 0.6,
        ZIndex = 5,
    }, Stage)
    local DistBtn = Create("TextButton", {
        Name = "Distance",
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(0, 150, 0, 14),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = o.DistanceText or "24m",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextStrokeTransparency = 0.6,
        ZIndex = 5,
    }, Stage)

    local boxW, boxH = 100, math.floor(SH * FILL)
    local function Layout()
        BoxBtn.Size = UDim2.new(0, boxW, 0, boxH)
        local cx = SW / 2
        HealthBtn.Size = UDim2.new(0, 10, 0, boxH)
        HealthBtn.Position = UDim2.new(0, cx - boxW / 2 - 8, 0.5, 0)
        NameBtn.Position = UDim2.new(0, cx, 0.5, boxH / 2 + 4)
        DistBtn.Position = UDim2.new(0, cx, 0.5, boxH / 2 + 18)
    end

    -- Painting --------------------------------------------------------------
    local function ColorOf(key, t)
        if colors[key] then return colors[key] end
        if key == "Box" then return t.Accent end
        if key == "Name" then return t.Text end
        if key == "Distance" then return t.SubText end
        local p = healthPct / 100
        return Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(70, 230, 110), p)
    end

    local function Paint()
        local t = Window.Theme
        Panel.BackgroundColor3 = t.Background
        Panel.BackgroundTransparency = t.Transparency
        PanelStroke.Color = Mix(t.Background, t.Accent, 0.5)
        PTitle.TextColor3 = t.Text
        PSub.TextColor3 = t.SubText
        Stage.BackgroundColor3 = Mix(t.Background, BLACK, 0.35)

        BoxStroke.Color = ColorOf("Box", t)
        BoxStroke.Transparency = states.Box and 0 or 0.88
        NameBtn.TextColor3 = ColorOf("Name", t)
        NameBtn.TextTransparency = states.Name and 0 or 0.85
        NameBtn.TextStrokeTransparency = states.Name and 0.6 or 1
        DistBtn.TextColor3 = ColorOf("Distance", t)
        DistBtn.TextTransparency = states.Distance and 0 or 0.85
        DistBtn.TextStrokeTransparency = states.Distance and 0.6 or 1
        HealthFill.BackgroundColor3 = ColorOf("Health", t)
        HealthFill.BackgroundTransparency = states.Health and 0 or 0.88
        HealthTrack.BackgroundTransparency = states.Health and 0.45 or 0.92
        HealthFill.Size = UDim2.new(1, 0, healthPct / 100, 0)
    end
    Window:Bind(Paint)

    local function Toggle(key)
        states[key] = not states[key]
        Paint()
        callback(key, states[key])
    end
    BoxBtn.MouseButton1Click:Connect(function() Toggle("Box") end)
    NameBtn.MouseButton1Click:Connect(function() Toggle("Name") end)
    DistBtn.MouseButton1Click:Connect(function() Toggle("Distance") end)
    HealthBtn.MouseButton1Click:Connect(function() Toggle("Health") end)

    -- Model -----------------------------------------------------------------
    local current, pivotOffset

    local function Mount(model)
        if current then current:Destroy() end
        current = model
        model.Parent = Viewport
        local bbcf, size = model:GetBoundingBox()
        if size.Y < 0.5 then
            model:Destroy()
            model = BuildDummy()
            current = model
            model.Parent = Viewport
            bbcf, size = model:GetBoundingBox()
        end
        pivotOffset = bbcf:ToObjectSpace(model:GetPivot())

        local dist = size.Y / FILL / (2 * math.tan(math.rad(Cam.FieldOfView / 2)))
        Cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, -dist), Vector3.zero)
        model:PivotTo(pivotOffset)

        -- box follows the model's real proportions
        boxH = math.floor(SH * FILL)
        boxW = math.clamp(math.floor(boxH * (size.X / size.Y) * 1.02), 40, SW - 50)
        Layout()
    end

    function Preview:SetModel(src)
        local model
        if typeof(src) == "Instance" then
            if src:IsA("Player") then src = src.Character end
            if src and src:IsA("Model") then model = CloneCharacter(src) end
        end
        model = model or CloneCharacter(LocalPlayer.Character) or BuildDummy()
        local ok = pcall(Mount, model)
        if not ok then
            pcall(Mount, BuildDummy())
        end
    end

    Window._Connect(RunService.RenderStepped, function()
        if not current or not Panel.Visible or not Window.Root.Visible then return end
        local angle
        if o.Spin then
            angle = (os.clock() * 1.1) % (math.pi * 2)
        else
            angle = math.sin(os.clock() * 1.2) * 0.55
        end
        current:PivotTo(CFrame.Angles(0, angle, 0) * pivotOffset)
    end)

    -- Public API ------------------------------------------------------------
    function Preview:Set(key, state, silent)
        if states[key] == nil then return end
        states[key] = state and true or false
        Paint()
        if not silent then callback(key, states[key]) end
    end
    function Preview:Get(key) return states[key] end
    function Preview:SetColor(key, color)
        colors[key] = color
        Paint()
    end
    function Preview:SetNameText(text) NameBtn.Text = tostring(text) end
    function Preview:SetDistanceText(text) DistBtn.Text = tostring(text) end
    function Preview:SetHealthPercent(p)
        healthPct = math.clamp(p, 0, 100)
        Paint()
    end
    function Preview:SetVisible(v) Panel.Visible = v and true or false end
    function Preview:Destroy() Panel:Destroy() end
    Preview.Panel = Panel

    Layout()
    Preview:SetModel(o.Model)
    Paint()
    return Preview
end

-------------------------------------------------
-- KEY SYSTEM
-------------------------------------------------
function Library:CreateKeySystem(options)
    options = options or {}
    local title = options.Title or "Key System"
    local link = options.Link or "https://example.com"
    local note = options.Note or "Enter your key below"
    local callback = options.Callback or function() end
    local accent = options.AccentColor or Defaults.AccentColor
    local bg = options.BackgroundColor or Defaults.BackgroundColor

    local ScreenGui = Create("ScreenGui", {
        Name = "sqservicesKeySystem",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000,
        IgnoreGuiInset = true,
    }, LocalPlayer:WaitForChild("PlayerGui"))

    local Overlay = Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = BLACK,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, ScreenGui)

    local Box = Create("Frame", {
        Name = "KeyBox",
        Size = UDim2.new(0, 350, 0, 220),
        Position = UDim2.new(0.5, -175, 0.5, -110),
        BackgroundColor3 = bg,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
    }, Overlay)
    Corner(Box, 14)
    Stroke(Box, Mix(bg, accent, 0.5), 1.3, 0.3)

    Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = Defaults.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Box)

    local Note = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 14, 0, 46),
        BackgroundTransparency = 1,
        Text = note,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Defaults.SubTextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Box)

    local TextBox = Create("TextBox", {
        Name = "KeyInput",
        Size = UDim2.new(1, -28, 0, 38),
        Position = UDim2.new(0, 14, 0, 76),
        BackgroundColor3 = Mix(bg, accent, 0.2),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        PlaceholderText = "Enter key here...",
        PlaceholderColor3 = Color3.fromRGB(105, 120, 155),
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(215, 225, 255),
        ClearTextOnFocus = false,
    }, Box)
    Corner(TextBox, 9)
    Stroke(TextBox, Mix(bg, accent, 0.55), 1, 0.45)
    Create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, TextBox)

    local Buttons = Create("Frame", {
        Size = UDim2.new(1, -28, 0, 38),
        Position = UDim2.new(0, 14, 0, 130),
        BackgroundTransparency = 1,
    }, Box)
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 12),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, Buttons)

    local Redeem = Create("TextButton", {
        Name = "Redeem",
        Size = UDim2.new(0, 148, 0, 36),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = WHITE,
        Text = "Redeem",
    }, Buttons)
    Corner(Redeem, 9)

    local GetKey = Create("TextButton", {
        Name = "GetKey",
        Size = UDim2.new(0, 148, 0, 36),
        BackgroundColor3 = Mix(bg, accent, 0.25),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(205, 220, 250),
        Text = "Get Key",
    }, Buttons)
    Corner(GetKey, 9)
    Stroke(GetKey, Mix(bg, accent, 0.55), 1, 0.45)

    Redeem.MouseEnter:Connect(function() Tween(Redeem, {BackgroundColor3 = Mix(accent, WHITE, 0.12)}, 0.15) end)
    Redeem.MouseLeave:Connect(function() Tween(Redeem, {BackgroundColor3 = accent}, 0.15) end)
    GetKey.MouseEnter:Connect(function() Tween(GetKey, {BackgroundTransparency = 0.05}, 0.15) end)
    GetKey.MouseLeave:Connect(function() Tween(GetKey, {BackgroundTransparency = 0.2}, 0.15) end)

    GetKey.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(tostring(link)) end
        GetKey.Text = "Copied!"
        task.delay(1.4, function()
            if GetKey and GetKey.Parent then GetKey.Text = "Get Key" end
        end)
    end)

    local function tryRedeem()
        local key = TextBox.Text:gsub("%s+", "")
        if key == "" then return end
        callback(key)
    end
    Redeem.MouseButton1Click:Connect(tryRedeem)
    TextBox.FocusLost:Connect(function(enter)
        if enter then tryRedeem() end
    end)

    return {
        Gui = ScreenGui,
        Destroy = function() ScreenGui:Destroy() end,
        SetNote = function(text) Note.Text = tostring(text) end,
    }
end

return Library
