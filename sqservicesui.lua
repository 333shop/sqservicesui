--[[
    sqservices.me UI Library
    Clean • Modern • Dark
    Version 2.6
    - SQ bubble logo next to title
    - Background ID / Image support
    - Smooth tab switching
    - Fullscreen blur when open
    - Close + Hide buttons
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local Defaults = {
    Title = "sqservices.me",
    Size = UDim2.new(0, 520, 0, 360),
    BackgroundColor = Color3.fromRGB(12, 16, 32),
    AccentColor = Color3.fromRGB(55, 110, 210),
    TextColor = Color3.fromRGB(220, 230, 255),
    SubTextColor = Color3.fromRGB(140, 155, 190),
    SidebarWidth = 128,
    CornerRadius = UDim.new(0, 10),
    BackgroundImage = nil, -- rbxassetid://123456 or https://...
}

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function createCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function createStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(40, 70, 130)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.4
    s.Parent = parent
    return s
end

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-------------------------------------------------
-- CreateWindow
-------------------------------------------------
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
    Window.BlurEffect = nil

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "sqservicesUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Enabled = true
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Fullscreen blur (when UI is open)
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "sqservicesBlur"
    Blur.Size = 0
    Blur.Parent = Lighting
    Window.BlurEffect = Blur

    tween(Blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = 18
    })

    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = config.Size
    Main.Position = UDim2.new(0.5, -config.Size.X.Offset / 2, 0.5, -config.Size.Y.Offset / 2)
    Main.BackgroundColor3 = config.BackgroundColor
    Main.BackgroundTransparency = 0
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Visible = true
    Main.Parent = ScreenGui

    createCorner(Main, config.CornerRadius)
    createStroke(Main, Color3.fromRGB(28, 42, 75), 1, 0.45)

    -- Background Image support (rbxassetid:// or http)
    local BgImage = Instance.new("ImageLabel")
    BgImage.Name = "BackgroundImage"
    BgImage.Size = UDim2.new(1, 0, 1, 0)
    BgImage.BackgroundTransparency = 1
    BgImage.ScaleType = Enum.ScaleType.Crop
    BgImage.ImageTransparency = 0.55
    BgImage.ZIndex = 0
    BgImage.Visible = false
    BgImage.Parent = Main
    createCorner(BgImage, config.CornerRadius)

    local function applyBackground(id)
        if not id or id == "" then
            BgImage.Visible = false
            BgImage.Image = ""
            return
        end

        local image = tostring(id)
        -- Allow pure number → convert to rbxassetid
        if tonumber(image) then
            image = "rbxassetid://" .. image
        end
        -- Allow raw asset id without prefix
        if not image:find("rbxassetid://") and not image:find("http") then
            image = "rbxassetid://" .. image
        end

        BgImage.Image = image
        BgImage.Visible = true
    end

    if config.BackgroundImage then
        applyBackground(config.BackgroundImage)
    end

    Window.SetBackground = applyBackground -- public method

    -------------------------------------------------
    -- Top Bar
    -------------------------------------------------
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundTransparency = 1
    TopBar.Active = true
    TopBar.ZIndex = 5
    TopBar.Parent = Main

    -- SQ Logo (bubble style)
    local Logo = Instance.new("Frame")
    Logo.Name = "SQLogo"
    Logo.Size = UDim2.new(0, 32, 0, 24)
    Logo.Position = UDim2.new(0, 12, 0.5, -12)
    Logo.BackgroundColor3 = config.AccentColor
    Logo.BorderSizePixel = 0
    Logo.ZIndex = 6
    Logo.Parent = TopBar
    createCorner(Logo, 8)

    local LogoText = Instance.new("TextLabel")
    LogoText.Name = "LogoText"
    LogoText.Size = UDim2.new(1, 0, 1, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "SQ"
    LogoText.Font = Enum.Font.FredokaOne -- bubble / rounded font
    LogoText.TextSize = 13
    LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoText.TextXAlignment = Enum.TextXAlignment.Center
    LogoText.TextYAlignment = Enum.TextYAlignment.Center
    LogoText.ZIndex = 7
    LogoText.Parent = Logo

    -- Title next to logo
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -140, 1, 0)
    Title.Position = UDim2.new(0, 52, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = config.TextColor
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 6
    Title.Parent = TopBar

    -- Close + Hide buttons (top right)
    local function makeTopButton(name, text, color, offsetX)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 28, 0, 22)
        btn.Position = UDim2.new(1, offsetX, 0.5, -11)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.15
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.ZIndex = 8
        btn.Parent = TopBar
        createCorner(btn, 6)
        return btn
    end

    local HideBtn = makeTopButton("Hide", "–", Color3.fromRGB(45, 70, 130), -70)
    local CloseBtn = makeTopButton("Close", "×", Color3.fromRGB(180, 55, 70), -36)

    -- Hover polish
    HideBtn.MouseEnter:Connect(function()
        tween(HideBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0 })
    end)
    HideBtn.MouseLeave:Connect(function()
        tween(HideBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.15 })
    end)
    CloseBtn.MouseEnter:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0 })
    end)
    CloseBtn.MouseLeave:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.15 })
    end)

    -- Divider under top bar
    local TopDivider = Instance.new("Frame")
    TopDivider.Size = UDim2.new(1, -24, 0, 1)
    TopDivider.Position = UDim2.new(0, 12, 1, -1)
    TopDivider.BackgroundColor3 = Color3.fromRGB(35, 50, 85)
    TopDivider.BackgroundTransparency = 0.3
    TopDivider.BorderSizePixel = 0
    TopDivider.ZIndex = 5
    TopDivider.Parent = TopBar

    -------------------------------------------------
    -- Content area
    -------------------------------------------------
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -42)
    Content.Position = UDim2.new(0, 0, 0, 42)
    Content.BackgroundTransparency = 1
    Content.ZIndex = 2
    Content.Parent = Main

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, config.SidebarWidth, 1, 0)
    Sidebar.BackgroundTransparency = 1
    Sidebar.Parent = Content

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Padding = UDim.new(0, 4)
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Parent = Sidebar

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 12)
    SidebarPadding.PaddingLeft = UDim.new(0, 10)
    SidebarPadding.PaddingRight = UDim.new(0, 8)
    SidebarPadding.Parent = Sidebar

    -- Vertical divider
    local SideDivider = Instance.new("Frame")
    SideDivider.Name = "SideDivider"
    SideDivider.Size = UDim2.new(0, 1, 1, -16)
    SideDivider.Position = UDim2.new(0, config.SidebarWidth, 0, 8)
    SideDivider.BackgroundColor3 = Color3.fromRGB(45, 65, 110)
    SideDivider.BackgroundTransparency = 0.55
    SideDivider.BorderSizePixel = 0
    SideDivider.ZIndex = 2
    SideDivider.Parent = Content

    -- Right panel
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Size = UDim2.new(1, -(config.SidebarWidth + 12), 1, 0)
    RightPanel.Position = UDim2.new(0, config.SidebarWidth + 12, 0, 0)
    RightPanel.BackgroundTransparency = 1
    RightPanel.Parent = Content

    local TabTitle = Instance.new("TextLabel")
    TabTitle.Name = "TabTitle"
    TabTitle.Size = UDim2.new(1, -16, 0, 28)
    TabTitle.Position = UDim2.new(0, 8, 0, 10)
    TabTitle.BackgroundTransparency = 1
    TabTitle.Text = ""
    TabTitle.Font = Enum.Font.GothamMedium
    TabTitle.TextSize = 15
    TabTitle.TextColor3 = config.TextColor
    TabTitle.TextXAlignment = Enum.TextXAlignment.Left
    TabTitle.Parent = RightPanel

    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -16, 1, -46)
    TabContainer.Position = UDim2.new(0, 8, 0, 40)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ClipsDescendants = true
    TabContainer.Parent = RightPanel

    Window.Main = Main
    Window.Sidebar = Sidebar
    Window.TabTitle = TabTitle
    Window.TabContainer = TabContainer
    Window.ScreenGui = ScreenGui
    Window.BgImage = BgImage

    -------------------------------------------------
    -- Close / Hide logic
    -------------------------------------------------
    local function setBlur(enabled)
        if not Window.BlurEffect then return end
        tween(Window.BlurEffect, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = enabled and 18 or 0
        })
    end

    function Window:Hide()
        if Window.IsHidden then return end
        Window.IsHidden = true
        tween(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, config.Size.X.Offset * 0.92, 0, config.Size.Y.Offset * 0.92)
        })
        task.delay(0.22, function()
            if Main and Main.Parent then
                Main.Visible = false
            end
        end)
        setBlur(false)
    end

    function Window:Show()
        if not Window.IsHidden then return end
        Window.IsHidden = false
        Main.Visible = true
        Main.BackgroundTransparency = 1
        Main.Size = UDim2.new(0, config.Size.X.Offset * 0.92, 0, config.Size.Y.Offset * 0.92)
        tween(Main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Size = config.Size
        })
        setBlur(true)
    end

    function Window:Toggle()
        if Window.IsHidden then
            Window:Show()
        else
            Window:Hide()
        end
    end

    function Window:Close()
        setBlur(false)
        tween(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, config.Size.X.Offset * 0.85, 0, config.Size.Y.Offset * 0.85)
        })
        task.delay(0.25, function()
            if ScreenGui and ScreenGui.Parent then
                ScreenGui:Destroy()
            end
            if Window.BlurEffect and Window.BlurEffect.Parent then
                Window.BlurEffect:Destroy()
            end
        end)
    end

    HideBtn.MouseButton1Click:Connect(function()
        Window:Hide()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Window:Close()
    end)

    -- Optional: keybind to re-open (RightShift)
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
            local delta = input.Position - DragStart
            Main.Position = UDim2.new(
                StartPos.X.Scale,
                StartPos.X.Offset + delta.X,
                StartPos.Y.Scale,
                StartPos.Y.Offset + delta.Y
            )
        end
    end)

    print("[sqservices.me] UI Library loaded (v2.6)")
    return Window
end

-------------------------------------------------
-- CreateTab
-------------------------------------------------
function Library:CreateTab(name)
    local Tab = {
        Name = name,
        Elements = {},
        Container = nil,
        Button = nil
    }

    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(22, 32, 58)
    Button.BackgroundTransparency = 1
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 13
    Button.TextColor3 = self.Config.SubTextColor
    Button.Text = name
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.LayoutOrder = #self.Tabs + 1
    Button.Parent = self.Sidebar

    local ButtonPadding = Instance.new("UIPadding")
    ButtonPadding.PaddingLeft = UDim.new(0, 10)
    ButtonPadding.Parent = Button

    createCorner(Button, 6)

    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = name .. "_Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 3
    ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(55, 85, 150)
    ContentFrame.ScrollBarImageTransparency = 0.4
    ContentFrame.Visible = false
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = self.TabContainer

    local ContentList = Instance.new("UIListLayout")
    ContentList.Padding = UDim.new(0, 8)
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Parent = ContentFrame

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 2)
    ContentPadding.PaddingBottom = UDim.new(0, 12)
    ContentPadding.Parent = ContentFrame

    Tab.Container = ContentFrame
    Tab.Button = Button

    Button.MouseEnter:Connect(function()
        if self.CurrentTab ~= Tab then
            tween(Button, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0.65,
                TextColor3 = self.Config.TextColor
            })
        end
    end)

    Button.MouseLeave:Connect(function()
        if self.CurrentTab ~= Tab then
            tween(Button, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 1,
                TextColor3 = self.Config.SubTextColor
            })
        end
    end)

    Button.MouseButton1Click:Connect(function()
        self:SelectTab(Tab)
    end)

    table.insert(self.Tabs, Tab)

    if #self.Tabs == 1 then
        self:SelectTab(Tab)
    end

    -- Button element
    function Tab:CreateButton(options)
        options = options or {}
        local name = options.Name or "Button"
        local callback = options.Callback or function() end

        local Btn = Instance.new("TextButton")
        Btn.Name = name
        Btn.Size = UDim2.new(0, 128, 0, 28)
        Btn.BackgroundColor3 = Color3.fromRGB(26, 38, 66)
        Btn.BorderSizePixel = 0
        Btn.AutoButtonColor = false
        Btn.Font = Enum.Font.GothamMedium
        Btn.TextSize = 12
        Btn.TextColor3 = Color3.fromRGB(200, 215, 245)
        Btn.Text = name
        Btn.Parent = self.Container

        createCorner(Btn, 6)
        createStroke(Btn, Color3.fromRGB(42, 65, 110), 1, 0.6)

        Btn.MouseEnter:Connect(function()
            tween(Btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(34, 52, 90) })
        end)
        Btn.MouseLeave:Connect(function()
            tween(Btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(26, 38, 66) })
        end)
        Btn.MouseButton1Click:Connect(function()
            callback()
        end)

        return Btn
    end

    -- Toggle
    function Tab:CreateToggle(options)
        options = options or {}
        local name = options.Name or "Toggle"
        local default = options.Default or false
        local callback = options.Callback or function() end
        local state = default

        local Holder = Instance.new("Frame")
        Holder.Name = name
        Holder.Size = UDim2.new(1, 0, 0, 30)
        Holder.BackgroundTransparency = 1
        Holder.Parent = self.Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -50, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextColor3 = Color3.fromRGB(185, 205, 240)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Holder

        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.Size = UDim2.new(0, 40, 0, 20)
        Track.Position = UDim2.new(1, -40, 0.5, -10)
        Track.BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(32, 44, 72)
        Track.BorderSizePixel = 0
        Track.Active = true
        Track.Parent = Holder
        createCorner(Track, 10)

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        Knob.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
        Knob.BorderSizePixel = 0
        Knob.Parent = Track
        createCorner(Knob, 8)

        local function setState(newState)
            state = newState
            tween(Track, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(32, 44, 72)
            })
            tween(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            })
            callback(state)
        end

        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setState(not state)
            end
        end)

        return Holder
    end

    -- Checkbox
    function Tab:CreateCheckbox(options)
        options = options or {}
        local name = options.Name or "Checkbox"
        local default = options.Default or false
        local callback = options.Callback or function() end
        local state = default

        local Holder = Instance.new("Frame")
        Holder.Name = name
        Holder.Size = UDim2.new(1, 0, 0, 28)
        Holder.BackgroundTransparency = 1
        Holder.Parent = self.Container

        local Box = Instance.new("Frame")
        Box.Name = "Box"
        Box.Size = UDim2.new(0, 20, 0, 20)
        Box.Position = UDim2.new(0, 0, 0.5, -10)
        Box.BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(26, 38, 66)
        Box.BorderSizePixel = 0
        Box.Active = true
        Box.Parent = Holder
        createCorner(Box, 5)
        createStroke(Box, Color3.fromRGB(50, 75, 130), 1, 0.5)

        local Check = Instance.new("TextLabel")
        Check.Size = UDim2.new(1, 0, 1, 0)
        Check.BackgroundTransparency = 1
        Check.Text = state and "✓" or ""
        Check.Font = Enum.Font.GothamBold
        Check.TextSize = 13
        Check.TextColor3 = Color3.fromRGB(255, 255, 255)
        Check.Parent = Box

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -28, 1, 0)
        Label.Position = UDim2.new(0, 26, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextColor3 = Color3.fromRGB(185, 205, 240)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Holder

        local function setState(newState)
            state = newState
            tween(Box, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(26, 38, 66)
            })
            Check.Text = state and "✓" or ""
            callback(state)
        end

        Box.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setState(not state)
            end
        end)

        return Holder
    end

    -- Slider
    function Tab:CreateSlider(options)
        options = options or {}
        local name = options.Name or "Slider"
        local min = options.Min or 0
        local max = options.Max or 100
        local default = options.Default or min
        local callback = options.Callback or function() end
        local value = default

        local Holder = Instance.new("Frame")
        Holder.Name = name
        Holder.Size = UDim2.new(1, 0, 0, 42)
        Holder.BackgroundTransparency = 1
        Holder.Parent = self.Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 16)
        Label.BackgroundTransparency = 1
        Label.Text = name .. "  •  " .. tostring(value)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextColor3 = Color3.fromRGB(180, 200, 240)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Holder

        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.Size = UDim2.new(1, 0, 0, 5)
        Track.Position = UDim2.new(0, 0, 0, 26)
        Track.BackgroundColor3 = Color3.fromRGB(28, 40, 68)
        Track.BorderSizePixel = 0
        Track.Active = true
        Track.Parent = Holder
        createCorner(Track, 3)

        local Fill = Instance.new("Frame")
        Fill.Name = "Fill"
        Fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
        Fill.BackgroundColor3 = Color3.fromRGB(55, 120, 230)
        Fill.BorderSizePixel = 0
        Fill.Parent = Track
        createCorner(Fill, 3)

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 12, 0, 12)
        Knob.Position = UDim2.new((value - min) / math.max(max - min, 1), -6, 0.5, -6)
        Knob.BackgroundColor3 = Color3.fromRGB(230, 238, 255)
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 2
        Knob.Active = true
        Knob.Parent = Track
        createCorner(Knob, 6)

        local Dragging = false

        local function update(input)
            local relative = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
            value = math.floor(min + (max - min) * relative + 0.5)

            local percent = (value - min) / math.max(max - min, 1)

            tween(Fill, TweenInfo.new(0.08), { Size = UDim2.new(percent, 0, 1, 0) })
            tween(Knob, TweenInfo.new(0.08), { Position = UDim2.new(percent, -6, 0.5, -6) })

            Label.Text = name .. "  •  " .. tostring(value)
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

        return Holder
    end

    -- Label
    function Tab:CreateLabel(text)
        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = tostring(text or "")
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextColor3 = Color3.fromRGB(160, 180, 220)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = self.Container
        return Label
    end

    -- Section
    function Tab:CreateSection(text)
        local Section = Instance.new("TextLabel")
        Section.Name = "Section"
        Section.Size = UDim2.new(1, 0, 0, 22)
        Section.BackgroundTransparency = 1
        Section.Text = tostring(text or "")
        Section.Font = Enum.Font.GothamMedium
        Section.TextSize = 12
        Section.TextColor3 = Color3.fromRGB(100, 130, 190)
        Section.TextXAlignment = Enum.TextXAlignment.Left
        Section.Parent = self.Container
        return Section
    end

    return Tab
end

-------------------------------------------------
-- Smooth SelectTab
-------------------------------------------------
function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end

    local fadeInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if self.CurrentTab then
        local oldBtn = self.CurrentTab.Button
        local oldFrame = self.CurrentTab.Container

        tween(oldBtn, fadeInfo, {
            BackgroundTransparency = 1,
            TextColor3 = self.Config.SubTextColor
        })

        -- fade out old content
        for _, child in ipairs(oldFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.BackgroundTransparency < 1 then
                tween(child, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
            end
        end
        task.delay(0.12, function()
            if oldFrame and oldFrame.Parent then
                oldFrame.Visible = false
            end
        end)
    end

    self.CurrentTab = tab
    self.TabTitle.Text = tab.Name
    tab.Container.Visible = true

    -- fade in new content slightly
    tab.Container.BackgroundTransparency = 1
    tween(tab.Container, TweenInfo.new(0.18), { BackgroundTransparency = 1 }) -- keep transparent

    tween(tab.Button, fadeInfo, {
        BackgroundTransparency = 0.35,
        TextColor3 = self.Config.TextColor
    })
end

-------------------------------------------------
-- KEY SYSTEM (unchanged + polished)
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
    Overlay.Name = "Overlay"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.45
    Overlay.BorderSizePixel = 0
    Overlay.Parent = ScreenGui

    local Box = Instance.new("Frame")
    Box.Name = "KeyBox"
    Box.Size = UDim2.new(0, 340, 0, 210)
    Box.Position = UDim2.new(0.5, -170, 0.5, -105)
    Box.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    Box.BorderSizePixel = 0
    Box.Parent = Overlay
    createCorner(Box, 12)
    createStroke(Box, Color3.fromRGB(40, 70, 130), 1.2, 0.35)

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -24, 0, 28)
    Title.Position = UDim2.new(0, 12, 0, 14)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Color3.fromRGB(220, 230, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Box

    local Note = Instance.new("TextLabel")
    Note.Size = UDim2.new(1, -24, 0, 18)
    Note.Position = UDim2.new(0, 12, 0, 42)
    Note.BackgroundTransparency = 1
    Note.Text = note
    Note.Font = Enum.Font.Gotham
    Note.TextSize = 12
    Note.TextColor3 = Color3.fromRGB(140, 155, 190)
    Note.TextXAlignment = Enum.TextXAlignment.Left
    Note.Parent = Box

    local TextBox = Instance.new("TextBox")
    TextBox.Name = "KeyInput"
    TextBox.Size = UDim2.new(1, -24, 0, 36)
    TextBox.Position = UDim2.new(0, 12, 0, 72)
    TextBox.BackgroundColor3 = Color3.fromRGB(20, 28, 50)
    TextBox.BorderSizePixel = 0
    TextBox.PlaceholderText = "Enter key here..."
    TextBox.PlaceholderColor3 = Color3.fromRGB(100, 115, 150)
    TextBox.Text = ""
    TextBox.Font = Enum.Font.Gotham
    TextBox.TextSize = 13
    TextBox.TextColor3 = Color3.fromRGB(210, 220, 255)
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = Box
    createCorner(TextBox, 8)
    createStroke(TextBox, Color3.fromRGB(45, 70, 120), 1, 0.4)

    local Buttons = Instance.new("Frame")
    Buttons.Name = "Buttons"
    Buttons.Size = UDim2.new(1, -24, 0, 34)
    Buttons.Position = UDim2.new(0, 12, 0, 124)
    Buttons.BackgroundTransparency = 1
    Buttons.Parent = Box

    local ButtonsLayout = Instance.new("UIListLayout")
    ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
    ButtonsLayout.Padding = UDim.new(0, 10)
    ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ButtonsLayout.Parent = Buttons

    local Redeem = Instance.new("TextButton")
    Redeem.Name = "Redeem"
    Redeem.Size = UDim2.new(0, 145, 0, 34)
    Redeem.BackgroundColor3 = Color3.fromRGB(45, 100, 200)
    Redeem.BorderSizePixel = 0
    Redeem.AutoButtonColor = false
    Redeem.Font = Enum.Font.GothamMedium
    Redeem.TextSize = 13
    Redeem.TextColor3 = Color3.fromRGB(255, 255, 255)
    Redeem.Text = "Redeem"
    Redeem.Parent = Buttons
    createCorner(Redeem, 8)

    local GetKey = Instance.new("TextButton")
    GetKey.Name = "GetKey"
    GetKey.Size = UDim2.new(0, 145, 0, 34)
    GetKey.BackgroundColor3 = Color3.fromRGB(26, 38, 66)
    GetKey.BorderSizePixel = 0
    GetKey.AutoButtonColor = false
    GetKey.Font = Enum.Font.GothamMedium
    GetKey.TextSize = 13
    GetKey.TextColor3 = Color3.fromRGB(200, 215, 245)
    GetKey.Text = "Get Key"
    GetKey.Parent = Buttons
    createCorner(GetKey, 8)
    createStroke(GetKey, Color3.fromRGB(50, 80, 140), 1, 0.5)

    Redeem.MouseEnter:Connect(function()
        tween(Redeem, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(55, 120, 230) })
    end)
    Redeem.MouseLeave:Connect(function()
        tween(Redeem, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(45, 100, 200) })
    end)
    GetKey.MouseEnter:Connect(function()
        tween(GetKey, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(34, 50, 88) })
    end)
    GetKey.MouseLeave:Connect(function()
        tween(GetKey, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(26, 38, 66) })
    end)

    GetKey.MouseButton1Click:Connect(function()
        setclipboard(tostring(link))
        GetKey.Text = "Copied!"
        task.delay(1.4, function()
            if GetKey and GetKey.Parent then
                GetKey.Text = "Get Key"
            end
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
        Destroy = function()
            ScreenGui:Destroy()
        end,
        SetNote = function(text)
            Note.Text = tostring(text)
        end
    }
end

return Library
