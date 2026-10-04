--[[
    sqservices.me UI Library
    Clean • Modern • Dark
    Version 3.1  – Transparent + clean tabs
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

-- Color palette matching the screenshot
local Colors = {
    Background   = Color3.fromRGB(18, 18, 32),
    Sidebar      = Color3.fromRGB(14, 14, 26),
    Card         = Color3.fromRGB(28, 28, 46),
    CardHover    = Color3.fromRGB(36, 36, 58),
    Accent       = Color3.fromRGB(100, 110, 255),
    AccentSoft   = Color3.fromRGB(80, 90, 220),
    Text         = Color3.fromRGB(235, 235, 250),
    SubText      = Color3.fromRGB(140, 145, 175),
    Section      = Color3.fromRGB(110, 115, 150),
    ToggleOn     = Color3.fromRGB(100, 110, 255),
    ToggleOff    = Color3.fromRGB(55, 55, 75),
    SliderTrack  = Color3.fromRGB(45, 45, 65),
    SliderFill   = Color3.fromRGB(100, 110, 255),
    Stroke       = Color3.fromRGB(70, 70, 110),
    Close        = Color3.fromRGB(200, 70, 80),
    Hide         = Color3.fromRGB(60, 60, 90),
}

local Defaults = {
    Title = "sqservices.me",
    Subtitle = "",
    Size = UDim2.new(0, 480, 0, 380),
    SidebarWidth = 150,
    CornerRadius = UDim.new(0, 14),
    BackgroundImage = nil,
    LogoText = "S",
}

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or Colors.Stroke
    s.Thickness = thick or 1
    s.Transparency = trans or 0.5
    s.Parent = parent
    return s
end

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

-------------------------------------------------
-- CreateWindow
-------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    for k, v in pairs(Defaults) do
        if config[k] == nil then config[k] = v end
    end

    local Window = setmetatable({}, Library)
    Window.Config = config
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.IsHidden = false
    Window.BlurEffect = nil

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "sqservicesUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Blur
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "sqservicesBlur"
    Blur.Size = 0
    Blur.Parent = Lighting
    Window.BlurEffect = Blur
    tween(Blur, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = 16 })

    -- Main container
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = config.Size
    Main.Position = UDim2.new(0.5, -config.Size.X.Offset / 2, 0.5, -config.Size.Y.Offset / 2)
    Main.BackgroundColor3 = Colors.Background
    Main.BackgroundTransparency = 0.18
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    corner(Main, config.CornerRadius)
    stroke(Main, Color3.fromRGB(80, 80, 130), 1, 0.45)

    -- Background image support
    local BgImage = Instance.new("ImageLabel")
    BgImage.Name = "BackgroundImage"
    BgImage.Size = UDim2.new(1, 0, 1, 0)
    BgImage.BackgroundTransparency = 1
    BgImage.ScaleType = Enum.ScaleType.Crop
    BgImage.ImageTransparency = 0.7
    BgImage.ZIndex = 0
    BgImage.Visible = false
    BgImage.Parent = Main
    corner(BgImage, config.CornerRadius)

    local function applyBackground(id)
        if not id or id == "" then
            BgImage.Visible = false
            BgImage.Image = ""
            return
        end
        local image = tostring(id)
        if tonumber(image) then image = "rbxassetid://" .. image end
        if not image:find("rbxassetid://") and not image:find("http") then
            image = "rbxassetid://" .. image
        end
        BgImage.Image = image
        BgImage.Visible = true
    end
    if config.BackgroundImage then applyBackground(config.BackgroundImage) end
    Window.SetBackground = applyBackground

    -------------------------------------------------
    -- LEFT SIDEBAR
    -------------------------------------------------
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, config.SidebarWidth, 1, 0)
    Sidebar.BackgroundColor3 = Colors.Sidebar
    Sidebar.BackgroundTransparency = 0.25
    Sidebar.BorderSizePixel = 0
    Sidebar.ZIndex = 2
    Sidebar.Parent = Main
    corner(Sidebar, config.CornerRadius)

    -- Fix right side of sidebar corner (cover)
    local SideFix = Instance.new("Frame")
    SideFix.Size = UDim2.new(0, 20, 1, 0)
    SideFix.Position = UDim2.new(1, -20, 0, 0)
    SideFix.BackgroundColor3 = Colors.Sidebar
    SideFix.BackgroundTransparency = 0.25
    SideFix.BorderSizePixel = 0
    SideFix.ZIndex = 2
    SideFix.Parent = Sidebar

    -- Logo area
    local LogoArea = Instance.new("Frame")
    LogoArea.Name = "LogoArea"
    LogoArea.Size = UDim2.new(1, 0, 0, 52)
    LogoArea.BackgroundTransparency = 1
    LogoArea.ZIndex = 3
    LogoArea.Parent = Sidebar

    local LogoCircle = Instance.new("Frame")
    LogoCircle.Name = "LogoCircle"
    LogoCircle.Size = UDim2.new(0, 28, 0, 28)
    LogoCircle.Position = UDim2.new(0, 14, 0.5, -14)
    LogoCircle.BackgroundColor3 = Colors.Accent
    LogoCircle.BorderSizePixel = 0
    LogoCircle.ZIndex = 4
    LogoCircle.Parent = LogoArea
    corner(LogoCircle, 8)

    local LogoLetter = Instance.new("TextLabel")
    LogoLetter.Size = UDim2.new(1, 0, 1, 0)
    LogoLetter.BackgroundTransparency = 1
    LogoLetter.Text = config.LogoText or "S"
    LogoLetter.Font = Enum.Font.GothamBold
    LogoLetter.TextSize = 14
    LogoLetter.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoLetter.ZIndex = 5
    LogoLetter.Parent = LogoCircle

    local LogoTitle = Instance.new("TextLabel")
    LogoTitle.Size = UDim2.new(1, -52, 1, 0)
    LogoTitle.Position = UDim2.new(0, 50, 0, 0)
    LogoTitle.BackgroundTransparency = 1
    LogoTitle.Text = config.Title
    LogoTitle.Font = Enum.Font.GothamMedium
    LogoTitle.TextSize = 13
    LogoTitle.TextColor3 = Colors.Text
    LogoTitle.TextXAlignment = Enum.TextXAlignment.Left
    LogoTitle.TextTruncate = Enum.TextTruncate.AtEnd
    LogoTitle.ZIndex = 4
    LogoTitle.Parent = LogoArea

    -- Tab buttons container
    local TabList = Instance.new("Frame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, -16, 1, -70)
    TabList.Position = UDim2.new(0, 8, 0, 56)
    TabList.BackgroundTransparency = 1
    TabList.ZIndex = 3
    TabList.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Parent = TabList

    -------------------------------------------------
    -- RIGHT CONTENT
    -------------------------------------------------
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -config.SidebarWidth, 1, 0)
    Content.Position = UDim2.new(0, config.SidebarWidth, 0, 0)
    Content.BackgroundTransparency = 1
    Content.ZIndex = 2
    Content.Parent = Main

    -- Top bar (title + buttons)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 48)
    TopBar.BackgroundTransparency = 1
    TopBar.Active = true
    TopBar.ZIndex = 5
    TopBar.Parent = Content

    local PageTitle = Instance.new("TextLabel")
    PageTitle.Name = "PageTitle"
    PageTitle.Size = UDim2.new(1, -90, 0, 22)
    PageTitle.Position = UDim2.new(0, 18, 0, 10)
    PageTitle.BackgroundTransparency = 1
    PageTitle.Text = ""
    PageTitle.Font = Enum.Font.GothamBold
    PageTitle.TextSize = 16
    PageTitle.TextColor3 = Colors.Text
    PageTitle.TextXAlignment = Enum.TextXAlignment.Left
    PageTitle.ZIndex = 6
    PageTitle.Parent = TopBar

    local PageSub = Instance.new("TextLabel")
    PageSub.Name = "PageSub"
    PageSub.Size = UDim2.new(1, -90, 0, 14)
    PageSub.Position = UDim2.new(0, 18, 0, 30)
    PageSub.BackgroundTransparency = 1
    PageSub.Text = ""
    PageSub.Font = Enum.Font.Gotham
    PageSub.TextSize = 11
    PageSub.TextColor3 = Colors.SubText
    PageSub.TextXAlignment = Enum.TextXAlignment.Left
    PageSub.ZIndex = 6
    PageSub.Parent = TopBar

    -- Hide / Close buttons
    local function makeIconBtn(name, text, bg, offset)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.Position = UDim2.new(1, offset, 0.5, -13)
        btn.BackgroundColor3 = bg
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        btn.Text = text
        btn.ZIndex = 8
        btn.Parent = TopBar
        corner(btn, 7)
        return btn
    end

    local HideBtn = makeIconBtn("Hide", "–", Colors.Hide, -68)
    local CloseBtn = makeIconBtn("Close", "×", Colors.Close, -36)

    HideBtn.MouseEnter:Connect(function() tween(HideBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0 }) end)
    HideBtn.MouseLeave:Connect(function() tween(HideBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.3 }) end)
    CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0 }) end)
    CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.3 }) end)

    -- Tab content container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -24, 1, -60)
    TabContainer.Position = UDim2.new(0, 12, 0, 52)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ClipsDescendants = true
    TabContainer.ZIndex = 3
    TabContainer.Parent = Content

    Window.Main = Main
    Window.Sidebar = TabList
    Window.PageTitle = PageTitle
    Window.PageSub = PageSub
    Window.TabContainer = TabContainer
    Window.ScreenGui = ScreenGui

    -------------------------------------------------
    -- Hide / Show / Close
    -------------------------------------------------
    local function setBlur(on)
        if Window.BlurEffect then
            tween(Window.BlurEffect, TweenInfo.new(0.3), { Size = on and 16 or 0 })
        end
    end

    function Window:Hide()
        if Window.IsHidden then return end
        Window.IsHidden = true
        tween(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, config.Size.X.Offset * 0.94, 0, config.Size.Y.Offset * 0.94)
        })
        task.delay(0.2, function()
            if Main and Main.Parent then Main.Visible = false end
        end)
        setBlur(false)
    end

    function Window:Show()
        if not Window.IsHidden then return end
        Window.IsHidden = false
        Main.Visible = true
        Main.BackgroundTransparency = 1
        Main.Size = UDim2.new(0, config.Size.X.Offset * 0.94, 0, config.Size.Y.Offset * 0.94)
        tween(Main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.18,
            Size = config.Size
        })
        setBlur(true)
    end

    function Window:Toggle()
        if Window.IsHidden then Window:Show() else Window:Hide() end
    end

    function Window:Close()
        setBlur(false)
        tween(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, config.Size.X.Offset * 0.88, 0, config.Size.Y.Offset * 0.88)
        })
        task.delay(0.22, function()
            if ScreenGui then ScreenGui:Destroy() end
            if Window.BlurEffect then Window.BlurEffect:Destroy() end
        end)
    end

    HideBtn.MouseButton1Click:Connect(function() Window:Hide() end)
    CloseBtn.MouseButton1Click:Connect(function() Window:Close() end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Window:Toggle()
        end
    end)

    -------------------------------------------------
    -- Dragging
    -------------------------------------------------
    local Dragging, DragStart, StartPos = false, nil, nil

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = Main.Position
        end
    end)
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - DragStart
            Main.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + d.X, StartPos.Y.Scale, StartPos.Y.Offset + d.Y)
        end
    end)

    -- Also allow dragging from logo area
    LogoArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = Main.Position
        end
    end)
    LogoArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)

    print("[sqservices.me] UI Library v3.0 loaded")
    return Window
end

-------------------------------------------------
-- CreateTab
-------------------------------------------------
function Library:CreateTab(name, icon)
    icon = icon or ""

    local Tab = {
        Name = name,
        Icon = icon,
        Elements = {},
        Container = nil,
        Button = nil,
        Subtitle = "",
    }

    -- Sidebar button
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 34)
    Button.BackgroundColor3 = Colors.Accent
    Button.BackgroundTransparency = 1
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Text = ""
    Button.LayoutOrder = #self.Tabs + 1
    Button.ZIndex = 4
    Button.Parent = self.Sidebar
    corner(Button, 8)

    local hasIcon = icon and icon ~= ""
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "Icon"
    IconLabel.Size = UDim2.new(0, hasIcon and 28 or 0, 1, 0)
    IconLabel.Position = UDim2.new(0, 6, 0, 0)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = hasIcon and icon or ""
    IconLabel.Font = Enum.Font.GothamMedium
    IconLabel.TextSize = 13
    IconLabel.TextColor3 = Colors.SubText
    IconLabel.Visible = hasIcon
    IconLabel.ZIndex = 5
    IconLabel.Parent = Button

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "Name"
    NameLabel.Size = UDim2.new(1, hasIcon and -40 or -20, 1, 0)
    NameLabel.Position = UDim2.new(0, hasIcon and 34 or 14, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.Font = Enum.Font.Gotham
    NameLabel.TextSize = 13
    NameLabel.TextColor3 = Colors.SubText
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.ZIndex = 5
    NameLabel.Parent = Button

    -- Content frame
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = name .. "_Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 3
    ContentFrame.ScrollBarImageColor3 = Colors.Accent
    ContentFrame.ScrollBarImageTransparency = 0.5
    ContentFrame.Visible = false
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.ZIndex = 3
    ContentFrame.Parent = self.TabContainer

    local ContentList = Instance.new("UIListLayout")
    ContentList.Padding = UDim.new(0, 6)
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Parent = ContentFrame

    padding(ContentFrame, 4, 16, 2, 6)

    Tab.Container = ContentFrame
    Tab.Button = Button
    Tab.IconLabel = IconLabel
    Tab.NameLabel = NameLabel

    -- Hover
    Button.MouseEnter:Connect(function()
        if self.CurrentTab ~= Tab then
            tween(Button, TweenInfo.new(0.15), { BackgroundTransparency = 0.85 })
            tween(NameLabel, TweenInfo.new(0.15), { TextColor3 = Colors.Text })
            tween(IconLabel, TweenInfo.new(0.15), { TextColor3 = Colors.Text })
        end
    end)
    Button.MouseLeave:Connect(function()
        if self.CurrentTab ~= Tab then
            tween(Button, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
            tween(NameLabel, TweenInfo.new(0.15), { TextColor3 = Colors.SubText })
            tween(IconLabel, TweenInfo.new(0.15), { TextColor3 = Colors.SubText })
        end
    end)
    Button.MouseButton1Click:Connect(function()
        self:SelectTab(Tab)
    end)

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then
        self:SelectTab(Tab)
    end

    -------------------------------------------------
    -- Element creators
    -------------------------------------------------

    -- Section header (like FIRE RATE, RECOIL)
    function Tab:CreateSection(text)
        local sec = Instance.new("TextLabel")
        sec.Name = "Section"
        sec.Size = UDim2.new(1, 0, 0, 20)
        sec.BackgroundTransparency = 1
        sec.Text = string.upper(tostring(text or ""))
        sec.Font = Enum.Font.GothamMedium
        sec.TextSize = 11
        sec.TextColor3 = Colors.Section
        sec.TextXAlignment = Enum.TextXAlignment.Left
        sec.ZIndex = 4
        sec.Parent = self.Container
        return sec
    end

    -- Modern toggle row (like Custom Fire Rate)
    function Tab:CreateToggle(options)
        options = options or {}
        local name = options.Name or "Toggle"
        local desc = options.Description or ""
        local default = options.Default or false
        local callback = options.Callback or function() end
        local state = default

        local Row = Instance.new("Frame")
        Row.Name = name
        Row.Size = UDim2.new(1, 0, 0, desc ~= "" and 48 or 38)
        Row.BackgroundColor3 = Colors.Card
        Row.BackgroundTransparency = 0.25
        Row.BorderSizePixel = 0
        Row.ZIndex = 4
        Row.Parent = self.Container
        corner(Row, 10)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -70, 0, 18)
        NameLbl.Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 10)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = name
        NameLbl.Font = Enum.Font.GothamMedium
        NameLbl.TextSize = 13
        NameLbl.TextColor3 = Colors.Text
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.ZIndex = 5
        NameLbl.Parent = Row

        if desc ~= "" then
            local DescLbl = Instance.new("TextLabel")
            DescLbl.Size = UDim2.new(1, -70, 0, 14)
            DescLbl.Position = UDim2.new(0, 14, 0, 26)
            DescLbl.BackgroundTransparency = 1
            DescLbl.Text = desc
            DescLbl.Font = Enum.Font.Gotham
            DescLbl.TextSize = 11
            DescLbl.TextColor3 = Colors.SubText
            DescLbl.TextXAlignment = Enum.TextXAlignment.Left
            DescLbl.ZIndex = 5
            DescLbl.Parent = Row
        end

        -- Pill toggle
        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.Size = UDim2.new(0, 42, 0, 22)
        Track.Position = UDim2.new(1, -54, 0.5, -11)
        Track.BackgroundColor3 = state and Colors.ToggleOn or Colors.ToggleOff
        Track.BorderSizePixel = 0
        Track.ZIndex = 5
        Track.Parent = Row
        corner(Track, 11)

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 6
        Knob.Parent = Track
        corner(Knob, 8)

        local function setState(v)
            state = v
            tween(Track, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Colors.ToggleOn or Colors.ToggleOff
            })
            tween(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            })
            callback(state)
        end

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.ZIndex = 7
        hit.Parent = Row
        hit.MouseButton1Click:Connect(function() setState(not state) end)

        return Row
    end

    -- Slider row (like Rounds Per Minute)
    function Tab:CreateSlider(options)
        options = options or {}
        local name = options.Name or "Slider"
        local min = options.Min or 0
        local max = options.Max or 100
        local default = options.Default or min
        local callback = options.Callback or function() end
        local value = default

        local Row = Instance.new("Frame")
        Row.Name = name
        Row.Size = UDim2.new(1, 0, 0, 52)
        Row.BackgroundColor3 = Colors.Card
        Row.BackgroundTransparency = 0.25
        Row.BorderSizePixel = 0
        Row.ZIndex = 4
        Row.Parent = self.Container
        corner(Row, 10)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -70, 0, 16)
        NameLbl.Position = UDim2.new(0, 14, 0, 8)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = name
        NameLbl.Font = Enum.Font.GothamMedium
        NameLbl.TextSize = 13
        NameLbl.TextColor3 = Colors.Text
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.ZIndex = 5
        NameLbl.Parent = Row

        local ValueLbl = Instance.new("TextLabel")
        ValueLbl.Size = UDim2.new(0, 50, 0, 16)
        ValueLbl.Position = UDim2.new(1, -60, 0, 8)
        ValueLbl.BackgroundTransparency = 1
        ValueLbl.Text = tostring(value)
        ValueLbl.Font = Enum.Font.GothamMedium
        ValueLbl.TextSize = 12
        ValueLbl.TextColor3 = Colors.SubText
        ValueLbl.TextXAlignment = Enum.TextXAlignment.Right
        ValueLbl.ZIndex = 5
        ValueLbl.Parent = Row

        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.Size = UDim2.new(1, -28, 0, 6)
        Track.Position = UDim2.new(0, 14, 0, 34)
        Track.BackgroundColor3 = Colors.SliderTrack
        Track.BorderSizePixel = 0
        Track.ZIndex = 5
        Track.Parent = Row
        corner(Track, 3)

        local Fill = Instance.new("Frame")
        Fill.Name = "Fill"
        Fill.Size = UDim2.new(math.clamp((value - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
        Fill.BackgroundColor3 = Colors.SliderFill
        Fill.BorderSizePixel = 0
        Fill.ZIndex = 6
        Fill.Parent = Track
        corner(Fill, 3)

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.Position = UDim2.new(math.clamp((value - min) / math.max(max - min, 1), 0, 1), -7, 0.5, -7)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 7
        Knob.Parent = Track
        corner(Knob, 7)

        local Dragging = false

        local function update(input)
            local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
            value = math.floor(min + (max - min) * rel + 0.5)
            local pct = (value - min) / math.max(max - min, 1)
            tween(Fill, TweenInfo.new(0.06), { Size = UDim2.new(pct, 0, 1, 0) })
            tween(Knob, TweenInfo.new(0.06), { Position = UDim2.new(pct, -7, 0.5, -7) })
            ValueLbl.Text = tostring(value)
            callback(value)
        end

        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                update(input)
            end
        end)
        Knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end)

        return Row
    end

    -- Button
    function Tab:CreateButton(options)
        options = options or {}
        local name = options.Name or "Button"
        local callback = options.Callback or function() end

        local Btn = Instance.new("TextButton")
        Btn.Name = name
        Btn.Size = UDim2.new(1, 0, 0, 36)
        Btn.BackgroundColor3 = Colors.Card
        Btn.BackgroundTransparency = 0.25
        Btn.BorderSizePixel = 0
        Btn.AutoButtonColor = false
        Btn.Font = Enum.Font.GothamMedium
        Btn.TextSize = 13
        Btn.TextColor3 = Colors.Text
        Btn.Text = name
        Btn.ZIndex = 4
        Btn.Parent = self.Container
        corner(Btn, 10)

        Btn.MouseEnter:Connect(function()
            tween(Btn, TweenInfo.new(0.12), { BackgroundColor3 = Colors.CardHover })
        end)
        Btn.MouseLeave:Connect(function()
            tween(Btn, TweenInfo.new(0.12), { BackgroundColor3 = Colors.Card })
        end)
        Btn.MouseButton1Click:Connect(function()
            callback()
        end)

        return Btn
    end

    -- Label
    function Tab:CreateLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Label"
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(text or "")
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = Colors.SubText
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 4
        lbl.Parent = self.Container
        return lbl
    end

    -- Checkbox (compact)
    function Tab:CreateCheckbox(options)
        options = options or {}
        local name = options.Name or "Checkbox"
        local default = options.Default or false
        local callback = options.Callback or function() end
        local state = default

        local Row = Instance.new("Frame")
        Row.Name = name
        Row.Size = UDim2.new(1, 0, 0, 36)
        Row.BackgroundColor3 = Colors.Card
        Row.BackgroundTransparency = 0.25
        Row.BorderSizePixel = 0
        Row.ZIndex = 4
        Row.Parent = self.Container
        corner(Row, 10)

        local Box = Instance.new("Frame")
        Box.Size = UDim2.new(0, 20, 0, 20)
        Box.Position = UDim2.new(0, 12, 0.5, -10)
        Box.BackgroundColor3 = state and Colors.Accent or Colors.ToggleOff
        Box.BorderSizePixel = 0
        Box.ZIndex = 5
        Box.Parent = Row
        corner(Box, 5)

        local Check = Instance.new("TextLabel")
        Check.Size = UDim2.new(1, 0, 1, 0)
        Check.BackgroundTransparency = 1
        Check.Text = state and "✓" or ""
        Check.Font = Enum.Font.GothamBold
        Check.TextSize = 13
        Check.TextColor3 = Color3.fromRGB(255, 255, 255)
        Check.ZIndex = 6
        Check.Parent = Box

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -50, 1, 0)
        NameLbl.Position = UDim2.new(0, 42, 0, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = name
        NameLbl.Font = Enum.Font.GothamMedium
        NameLbl.TextSize = 13
        NameLbl.TextColor3 = Colors.Text
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.ZIndex = 5
        NameLbl.Parent = Row

        local function setState(v)
            state = v
            tween(Box, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Colors.Accent or Colors.ToggleOff
            })
            Check.Text = state and "✓" or ""
            callback(state)
        end

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.ZIndex = 7
        hit.Parent = Row
        hit.MouseButton1Click:Connect(function() setState(not state) end)

        return Row
    end

    return Tab
end

-------------------------------------------------
-- Smooth SelectTab
-------------------------------------------------
function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end

    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if self.CurrentTab then
        local old = self.CurrentTab
        tween(old.Button, info, { BackgroundTransparency = 1 })
        tween(old.NameLabel, info, { TextColor3 = Colors.SubText })
        tween(old.IconLabel, info, { TextColor3 = Colors.SubText })
        old.Container.Visible = false
    end

    self.CurrentTab = tab
    self.PageTitle.Text = tab.Name
    self.PageSub.Text = tab.Subtitle or ""

    tab.Container.Visible = true
    tween(tab.Button, info, { BackgroundTransparency = 0 })
    tween(tab.NameLabel, info, { TextColor3 = Color3.fromRGB(255, 255, 255) })
    tween(tab.IconLabel, info, { TextColor3 = Color3.fromRGB(255, 255, 255) })
end

-------------------------------------------------
-- Key System (kept + restyled)
-------------------------------------------------
function Library:CreateKeySystem(options)
    options = options or {}
    local title = options.Title or "Key System"
    local link = options.Link or "https://example.com"
    local note = options.Note or "Enter your key below"
    local callback = options.Callback or function() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "sqservicesKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local Overlay = Instance.new("Frame")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.BorderSizePixel = 0
    Overlay.Parent = ScreenGui

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 340, 0, 210)
    Box.Position = UDim2.new(0.5, -170, 0.5, -105)
    Box.BackgroundColor3 = Colors.Background
    Box.BorderSizePixel = 0
    Box.Parent = Overlay
    corner(Box, 14)
    stroke(Box, Colors.Stroke, 1, 0.4)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -24, 0, 28)
    Title.Position = UDim2.new(0, 12, 0, 14)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Colors.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Box

    local Note = Instance.new("TextLabel")
    Note.Size = UDim2.new(1, -24, 0, 18)
    Note.Position = UDim2.new(0, 12, 0, 42)
    Note.BackgroundTransparency = 1
    Note.Text = note
    Note.Font = Enum.Font.Gotham
    Note.TextSize = 12
    Note.TextColor3 = Colors.SubText
    Note.TextXAlignment = Enum.TextXAlignment.Left
    Note.Parent = Box

    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, -24, 0, 36)
    TextBox.Position = UDim2.new(0, 12, 0, 72)
    TextBox.BackgroundColor3 = Colors.Card
    TextBox.BorderSizePixel = 0
    TextBox.PlaceholderText = "Enter key here..."
    TextBox.PlaceholderColor3 = Colors.SubText
    TextBox.Text = ""
    TextBox.Font = Enum.Font.Gotham
    TextBox.TextSize = 13
    TextBox.TextColor3 = Colors.Text
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = Box
    corner(TextBox, 8)

    local Buttons = Instance.new("Frame")
    Buttons.Size = UDim2.new(1, -24, 0, 34)
    Buttons.Position = UDim2.new(0, 12, 0, 124)
    Buttons.BackgroundTransparency = 1
    Buttons.Parent = Box

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = Buttons

    local Redeem = Instance.new("TextButton")
    Redeem.Size = UDim2.new(0, 145, 0, 34)
    Redeem.BackgroundColor3 = Colors.Accent
    Redeem.BorderSizePixel = 0
    Redeem.AutoButtonColor = false
    Redeem.Font = Enum.Font.GothamMedium
    Redeem.TextSize = 13
    Redeem.TextColor3 = Color3.fromRGB(255, 255, 255)
    Redeem.Text = "Redeem"
    Redeem.Parent = Buttons
    corner(Redeem, 8)

    local GetKey = Instance.new("TextButton")
    GetKey.Size = UDim2.new(0, 145, 0, 34)
    GetKey.BackgroundColor3 = Colors.Card
    GetKey.BorderSizePixel = 0
    GetKey.AutoButtonColor = false
    GetKey.Font = Enum.Font.GothamMedium
    GetKey.TextSize = 13
    GetKey.TextColor3 = Colors.Text
    GetKey.Text = "Get Key"
    GetKey.Parent = Buttons
    corner(GetKey, 8)

    Redeem.MouseEnter:Connect(function() tween(Redeem, TweenInfo.new(0.12), { BackgroundColor3 = Colors.AccentSoft }) end)
    Redeem.MouseLeave:Connect(function() tween(Redeem, TweenInfo.new(0.12), { BackgroundColor3 = Colors.Accent }) end)
    GetKey.MouseEnter:Connect(function() tween(GetKey, TweenInfo.new(0.12), { BackgroundColor3 = Colors.CardHover }) end)
    GetKey.MouseLeave:Connect(function() tween(GetKey, TweenInfo.new(0.12), { BackgroundColor3 = Colors.Card }) end)

    GetKey.MouseButton1Click:Connect(function()
        setclipboard(tostring(link))
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
        SetNote = function(text) Note.Text = tostring(text) end
    }
end

return Library
