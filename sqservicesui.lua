--[[
    sqservices.me UI Library
    Clean • Modern • Dark
    Version 2.5  (Key System added)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
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
    BackgroundImage = nil,
}

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

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "sqservicesUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Enabled = true
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

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

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = config.CornerRadius
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(28, 42, 75)
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.45
    MainStroke.Parent = Main

    if config.BackgroundImage and config.BackgroundImage ~= "" then
        local BgImage = Instance.new("ImageLabel")
        BgImage.Name = "BackgroundImage"
        BgImage.Size = UDim2.new(1, 0, 1, 0)
        BgImage.BackgroundTransparency = 1
        BgImage.Image = config.BackgroundImage
        BgImage.ScaleType = Enum.ScaleType.Crop
        BgImage.ImageTransparency = 0.6
        BgImage.ZIndex = 0
        BgImage.Parent = Main

        local ImgCorner = Instance.new("UICorner")
        ImgCorner.CornerRadius = config.CornerRadius
        ImgCorner.Parent = BgImage
    end

    -- Top bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundTransparency = 1
    TopBar.Active = true
    TopBar.ZIndex = 3
    TopBar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -24, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = config.TextColor
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local TopDivider = Instance.new("Frame")
    TopDivider.Size = UDim2.new(1, -24, 0, 1)
    TopDivider.Position = UDim2.new(0, 12, 1, -1)
    TopDivider.BackgroundColor3 = Color3.fromRGB(35, 50, 85)
    TopDivider.BackgroundTransparency = 0.3
    TopDivider.BorderSizePixel = 0
    TopDivider.Parent = TopBar

    -- Content area
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -40)
    Content.Position = UDim2.new(0, 0, 0, 40)
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

    -- Transparent vertical divider
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
    TabContainer.Parent = RightPanel

    Window.Main = Main
    Window.Sidebar = Sidebar
    Window.TabTitle = TabTitle
    Window.TabContainer = TabContainer
    Window.ScreenGui = ScreenGui

    -- Dragging
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

    print("[sqservices.me] UI Library loaded (v2.5)")
    return Window
end

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

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = Button

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
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.65,
                TextColor3 = self.Config.TextColor
            }):Play()
        end
    end)

    Button.MouseLeave:Connect(function()
        if self.CurrentTab ~= Tab then
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
                TextColor3 = self.Config.SubTextColor
            }):Play()
        end
    end)

    Button.MouseButton1Click:Connect(function()
        self:SelectTab(Tab)
    end)

    table.insert(self.Tabs, Tab)

    if #self.Tabs == 1 then
        self:SelectTab(Tab)
    end

    -- Button
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

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 6)
        Corner.Parent = Btn

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(42, 65, 110)
        Stroke.Thickness = 1
        Stroke.Transparency = 0.6
        Stroke.Parent = Btn

        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(34, 52, 90)
            }):Play()
        end)

        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(26, 38, 66)
            }):Play()
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

        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        Knob.BackgroundColor3 = Color3.fromRGB(235, 240, 255)
        Knob.BorderSizePixel = 0
        Knob.Parent = Track

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        local function setState(newState)
            state = newState
            TweenService:Create(Track, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(32, 44, 72)
            }):Play()
            TweenService:Create(Knob, TweenInfo.new(0.18), {
                Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            }):Play()
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
        Box.Size = UDim2.new(0, 18, 0, 18)
        Box.Position = UDim2.new(0, 0, 0.5, -9)
        Box.BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(26, 38, 66)
        Box.BorderSizePixel = 0
        Box.Active = true
        Box.Parent = Holder

        local BoxCorner = Instance.new("UICorner")
        BoxCorner.CornerRadius = UDim.new(0, 4)
        BoxCorner.Parent = Box

        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Color = Color3.fromRGB(48, 72, 120)
        BoxStroke.Thickness = 1
        BoxStroke.Transparency = 0.55
        BoxStroke.Parent = Box

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
            TweenService:Create(Box, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(26, 38, 66)
            }):Play()
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

        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track

        local Fill = Instance.new("Frame")
        Fill.Name = "Fill"
        Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        Fill.BackgroundColor3 = Color3.fromRGB(55, 120, 230)
        Fill.BorderSizePixel = 0
        Fill.Parent = Track

        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = Fill

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 12, 0, 12)
        Knob.Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6)
        Knob.BackgroundColor3 = Color3.fromRGB(230, 238, 255)
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 2
        Knob.Active = true
        Knob.Parent = Track

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        local Dragging = false

        local function update(input)
            local relative = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
            value = math.floor(min + (max - min) * relative + 0.5)

            local percent = (value - min) / (max - min)

            TweenService:Create(Fill, TweenInfo.new(0.08), {
                Size = UDim2.new(percent, 0, 1, 0)
            }):Play()

            TweenService:Create(Knob, TweenInfo.new(0.08), {
                Position = UDim2.new(percent, -6, 0.5, -6)
            }):Play()

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

    return Tab
end

function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end

    if self.CurrentTab then
        TweenService:Create(self.CurrentTab.Button, TweenInfo.new(0.15), {
            BackgroundTransparency = 1,
            TextColor3 = self.Config.SubTextColor
        }):Play()
        self.CurrentTab.Container.Visible = false
    end

    self.CurrentTab = tab
    self.TabTitle.Text = tab.Name
    tab.Container.Visible = true

    TweenService:Create(tab.Button, TweenInfo.new(0.15), {
        BackgroundTransparency = 0.4,
        TextColor3 = self.Config.TextColor
    }):Play()
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

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "sqservicesKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Dim background
    local Overlay = Instance.new("Frame")
    Overlay.Name = "Overlay"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.45
    Overlay.BorderSizePixel = 0
    Overlay.Parent = ScreenGui

    -- Main Key Box
    local Box = Instance.new("Frame")
    Box.Name = "KeyBox"
    Box.Size = UDim2.new(0, 340, 0, 210)
    Box.Position = UDim2.new(0.5, -170, 0.5, -105)
    Box.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    Box.BorderSizePixel = 0
    Box.Parent = Overlay

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 12)
    BoxCorner.Parent = Box

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = Color3.fromRGB(40, 70, 130)
    BoxStroke.Thickness = 1.2
    BoxStroke.Transparency = 0.35
    BoxStroke.Parent = Box

    -- Title
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

    -- Note / subtitle
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

    -- Rounded TextBox
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

    local TextBoxCorner = Instance.new("UICorner")
    TextBoxCorner.CornerRadius = UDim.new(0, 8)
    TextBoxCorner.Parent = TextBox

    local TextBoxStroke = Instance.new("UIStroke")
    TextBoxStroke.Color = Color3.fromRGB(45, 70, 120)
    TextBoxStroke.Thickness = 1
    TextBoxStroke.Transparency = 0.5
    TextBoxStroke.Parent = TextBox

    local TextBoxPadding = Instance.new("UIPadding")
    TextBoxPadding.PaddingLeft = UDim.new(0, 12)
    TextBoxPadding.PaddingRight = UDim.new(0, 12)
    TextBoxPadding.Parent = TextBox

    -- Buttons Holder
    local Buttons = Instance.new("Frame")
    Buttons.Size = UDim2.new(1, -24, 0, 36)
    Buttons.Position = UDim2.new(0, 12, 0, 124)
    Buttons.BackgroundTransparency = 1
    Buttons.Parent = Box

    local ButtonsLayout = Instance.new("UIListLayout")
    ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
    ButtonsLayout.Padding = UDim.new(0, 10)
    ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ButtonsLayout.Parent = Buttons

    -- Redeem Button
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

    local RedeemCorner = Instance.new("UICorner")
    RedeemCorner.CornerRadius = UDim.new(0, 8)
    RedeemCorner.Parent = Redeem

    -- Get Key Button
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

    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 8)
    GetKeyCorner.Parent = GetKey

    local GetKeyStroke = Instance.new("UIStroke")
    GetKeyStroke.Color = Color3.fromRGB(50, 80, 140)
    GetKeyStroke.Thickness = 1
    GetKeyStroke.Transparency = 0.5
    GetKeyStroke.Parent = GetKey

    -- Hover effects
    Redeem.MouseEnter:Connect(function()
        TweenService:Create(Redeem, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(55, 120, 230)
        }):Play()
    end)
    Redeem.MouseLeave:Connect(function()
        TweenService:Create(Redeem, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45, 100, 200)
        }):Play()
    end)

    GetKey.MouseEnter:Connect(function()
        TweenService:Create(GetKey, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(34, 50, 88)
        }):Play()
    end)
    GetKey.MouseLeave:Connect(function()
        TweenService:Create(GetKey, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(26, 38, 66)
        }):Play()
    end)

    -- Get Key → copy link
    GetKey.MouseButton1Click:Connect(function()
        setclipboard(tostring(link))
        GetKey.Text = "Copied!"
        task.delay(1.4, function()
            if GetKey and GetKey.Parent then
                GetKey.Text = "Get Key"
            end
        end)
    end)

    -- Redeem
    local function tryRedeem()
        local key = TextBox.Text:gsub("%s+", "")
        if key == "" then return end
        callback(key)
    end

    Redeem.MouseButton1Click:Connect(tryRedeem)

    TextBox.FocusLost:Connect(function(enter)
        if enter then
            tryRedeem()
        end
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
