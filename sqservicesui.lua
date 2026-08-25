--[[
    sqservices.me UI Library
    Clean • Modern • Dark Blue
    Version 2.2
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
    SidebarWidth = 130,
    CornerRadius = UDim.new(0, 10),
    BackgroundImage = nil, -- "rbxassetid://..." or image URL
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
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = config.Size
    Main.Position = UDim2.new(0.5, -config.Size.X.Offset / 2, 0.5, -config.Size.Y.Offset / 2)
    Main.BackgroundColor3 = config.BackgroundColor
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = config.CornerRadius
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(28, 42, 75)
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.4
    MainStroke.Parent = Main

    -- Optional background image
    if config.BackgroundImage and config.BackgroundImage ~= "" then
        local BgImage = Instance.new("ImageLabel")
        BgImage.Name = "BackgroundImage"
        BgImage.Size = UDim2.new(1, 0, 1, 0)
        BgImage.BackgroundTransparency = 1
        BgImage.Image = config.BackgroundImage
        BgImage.ScaleType = Enum.ScaleType.Crop
        BgImage.ImageTransparency = 0.55
        BgImage.ZIndex = 0
        BgImage.Parent = Main

        local ImgCorner = Instance.new("UICorner")
        ImgCorner.CornerRadius = config.CornerRadius
        ImgCorner.Parent = BgImage
    end

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundTransparency = 1
    TopBar.ZIndex = 2
    TopBar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 15
    Title.TextColor3 = config.TextColor
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -24, 0, 1)
    Divider.Position = UDim2.new(0, 12, 1, -1)
    Divider.BackgroundColor3 = Color3.fromRGB(32, 48, 85)
    Divider.BorderSizePixel = 0
    Divider.Parent = TopBar

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -42)
    Content.Position = UDim2.new(0, 0, 0, 42)
    Content.BackgroundTransparency = 1
    Content.ZIndex = 2
    Content.Parent = Main

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, config.SidebarWidth, 1, 0)
    Sidebar.BackgroundTransparency = 1
    Sidebar.Parent = Content

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Padding = UDim.new(0, 5)
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Parent = Sidebar

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 12)
    SidebarPadding.PaddingLeft = UDim.new(0, 10)
    SidebarPadding.PaddingRight = UDim.new(0, 8)
    SidebarPadding.Parent = Sidebar

    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Size = UDim2.new(1, -(config.SidebarWidth + 10), 1, 0)
    RightPanel.Position = UDim2.new(0, config.SidebarWidth + 10, 0, 0)
    RightPanel.BackgroundTransparency = 1
    RightPanel.Parent = Content

    local TabTitle = Instance.new("TextLabel")
    TabTitle.Name = "TabTitle"
    TabTitle.Size = UDim2.new(1, -20, 0, 30)
    TabTitle.Position = UDim2.new(0, 10, 0, 10)
    TabTitle.BackgroundTransparency = 1
    TabTitle.Text = ""
    TabTitle.Font = Enum.Font.GothamMedium
    TabTitle.TextSize = 17
    TabTitle.TextColor3 = config.TextColor
    TabTitle.TextXAlignment = Enum.TextXAlignment.Left
    TabTitle.Parent = RightPanel

    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -20, 1, -50)
    TabContainer.Position = UDim2.new(0, 10, 0, 44)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = RightPanel

    Window.Main = Main
    Window.Sidebar = Sidebar
    Window.TabTitle = TabTitle
    Window.TabContainer = TabContainer
    Window.ScreenGui = ScreenGui

    -- Dragging (mouse + touch)
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

    print("[sqservices.me] UI Library loaded (v2.2)")
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
    Button.Size = UDim2.new(1, 0, 0, 32)
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
    ButtonPadding.PaddingLeft = UDim.new(0, 12)
    ButtonPadding.Parent = Button

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 7)
    ButtonCorner.Parent = Button

    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = name .. "_Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 3
    ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(55, 85, 150)
    ContentFrame.Visible = false
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = self.TabContainer

    local ContentList = Instance.new("UIListLayout")
    ContentList.Padding = UDim.new(0, 8)
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Parent = ContentFrame

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 4)
    ContentPadding.PaddingBottom = UDim.new(0, 14)
    ContentPadding.Parent = ContentFrame

    Tab.Container = ContentFrame
    Tab.Button = Button

    Button.MouseEnter:Connect(function()
        if self.CurrentTab ~= Tab then
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.6,
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

    -- ===== Button =====
    function Tab:CreateButton(options)
        options = options or {}
        local name = options.Name or "Button"
        local callback = options.Callback or function() end

        local Btn = Instance.new("TextButton")
        Btn.Name = name
        Btn.Size = UDim2.new(0, 132, 0, 30)
        Btn.BackgroundColor3 = Color3.fromRGB(28, 42, 72)
        Btn.BorderSizePixel = 0
        Btn.AutoButtonColor = false
        Btn.Font = Enum.Font.GothamMedium
        Btn.TextSize = 12
        Btn.TextColor3 = Color3.fromRGB(200, 215, 245)
        Btn.Text = name
        Btn.Parent = self.Container

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 7)
        Corner.Parent = Btn

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(45, 70, 120)
        Stroke.Thickness = 1
        Stroke.Transparency = 0.55
        Stroke.Parent = Btn

        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(38, 58, 98)
            }):Play()
        end)

        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(28, 42, 72)
            }):Play()
        end)

        Btn.MouseButton1Click:Connect(function()
            callback()
        end)

        return Btn
    end

    -- ===== Toggle Switch =====
    function Tab:CreateToggle(options)
        options = options or {}
        local name = options.Name or "Toggle"
        local default = options.Default or false
        local callback = options.Callback or function() end
        local state = default

        local Holder = Instance.new("Frame")
        Holder.Name = name
        Holder.Size = UDim2.new(1, 0, 0, 32)
        Holder.BackgroundTransparency = 1
        Holder.Parent = self.Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -54, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextColor3 = Color3.fromRGB(185, 205, 240)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Holder

        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.Size = UDim2.new(0, 42, 0, 22)
        Track.Position = UDim2.new(1, -42, 0.5, -11)
        Track.BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(35, 48, 78)
        Track.BorderSizePixel = 0
        Track.Parent = Holder

        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        Knob.BackgroundColor3 = Color3.fromRGB(235, 240, 255)
        Knob.BorderSizePixel = 0
        Knob.Parent = Track

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        local function setState(newState)
            state = newState
            TweenService:Create(Track, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(35, 48, 78)
            }):Play()
            TweenService:Create(Knob, TweenInfo.new(0.18), {
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
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

    -- ===== Checkbox =====
    function Tab:CreateCheckbox(options)
        options = options or {}
        local name = options.Name or "Checkbox"
        local default = options.Default or false
        local callback = options.Callback or function() end
        local state = default

        local Holder = Instance.new("Frame")
        Holder.Name = name
        Holder.Size = UDim2.new(1, 0, 0, 30)
        Holder.BackgroundTransparency = 1
        Holder.Parent = self.Container

        local Box = Instance.new("Frame")
        Box.Name = "Box"
        Box.Size = UDim2.new(0, 20, 0, 20)
        Box.Position = UDim2.new(0, 0, 0.5, -10)
        Box.BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(28, 40, 68)
        Box.BorderSizePixel = 0
        Box.Parent = Holder

        local BoxCorner = Instance.new("UICorner")
        BoxCorner.CornerRadius = UDim.new(0, 5)
        BoxCorner.Parent = Box

        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Color = Color3.fromRGB(50, 75, 130)
        BoxStroke.Thickness = 1
        BoxStroke.Transparency = 0.5
        BoxStroke.Parent = Box

        local Check = Instance.new("TextLabel")
        Check.Size = UDim2.new(1, 0, 1, 0)
        Check.BackgroundTransparency = 1
        Check.Text = state and "✓" or ""
        Check.Font = Enum.Font.GothamBold
        Check.TextSize = 14
        Check.TextColor3 = Color3.fromRGB(255, 255, 255)
        Check.Parent = Box

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -30, 1, 0)
        Label.Position = UDim2.new(0, 28, 0, 0)
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
                BackgroundColor3 = state and Color3.fromRGB(45, 100, 200) or Color3.fromRGB(28, 40, 68)
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

    -- ===== SmoothSlider =====
    function Tab:CreateSlider(options)
        options = options or {}
        local name = options.Name or "Slider"
        local min = options.Min or 0
        local max = options.Max or 100
        local default = options.Default or min
        local callback = options.Callback or function() end

        local value = math.clamp(default, min, max)

        local Holder = Instance.new("Frame")
        Holder.Name = name
        Holder.Size = UDim2.new(1, 0, 0, 48)
        Holder.BackgroundTransparency = 1
        Holder.Parent = self.Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 18)
        Label.BackgroundTransparency = 1
        Label.Text = name .. "  •  " .. tostring(value)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextColor3 = Color3.fromRGB(180, 200, 240)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Holder

        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.Size = UDim2.new(1, 0, 0, 6)
        Track.Position = UDim2.new(0, 0, 0, 28)
        Track.BackgroundColor3 = Color3.fromRGB(28, 40, 68)
        Track.BorderSizePixel = 0
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
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
        Knob.BackgroundColor3 = Color3.fromRGB(230, 238, 255)
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 2
        Knob.Parent = Track

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        local Dragging = false

        local function update(input)
            local relative = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * relative + 0.5)

            local percent = (value - min) / (max - min)

            TweenService:Create(Fill, TweenInfo.new(0.08), {
                Size = UDim2.new(percent, 0, 1, 0)
            }):Play()

            TweenService:Create(Knob, TweenInfo.new(0.08), {
                Position = UDim2.new(percent, -7, 0.5, -7)
            }):Play()

            Label.Text = name .. "  •  " .. tostring(value)
            callback(value)
        end

        -- Mouse + Touch support
        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                update(input)
            end
        end)

        Track.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
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
        BackgroundTransparency = 0.35,
        TextColor3 = self.Config.TextColor
    }):Play()
end

return Library
