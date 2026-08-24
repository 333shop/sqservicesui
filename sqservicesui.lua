--[[
    sqservices.me UI Library
    Clean • Modern • Dark Blue
    Version 2.0
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local Defaults = {
    Title = "sqservices.me",
    Size = UDim2.new(0, 520, 0, 340),
    BackgroundColor = Color3.fromRGB(12, 16, 32),
    AccentColor = Color3.fromRGB(40, 90, 180),
    TextColor = Color3.fromRGB(220, 230, 255),
    SubTextColor = Color3.fromRGB(140, 155, 190),
    SidebarWidth = 130,
    CornerRadius = UDim.new(0, 10),
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
    MainStroke.Color = Color3.fromRGB(30, 45, 80)
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.35
    MainStroke.Parent = Main

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title
    Title.Font = Enum.Font.Code
    Title.TextSize = 16
    Title.TextColor3 = config.TextColor
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -24, 0, 1)
    Divider.Position = UDim2.new(0, 12, 1, -1)
    Divider.BackgroundColor3 = Color3.fromRGB(35, 50, 90)
    Divider.BorderSizePixel = 0
    Divider.Parent = TopBar

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -42)
    Content.Position = UDim2.new(0, 0, 0, 42)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, config.SidebarWidth, 1, 0)
    Sidebar.BackgroundTransparency = 1
    Sidebar.Parent = Content

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Padding = UDim.new(0, 6)
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Parent = Sidebar

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 14)
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
    TabTitle.Size = UDim2.new(1, -20, 0, 32)
    TabTitle.Position = UDim2.new(0, 10, 0, 12)
    TabTitle.BackgroundTransparency = 1
    TabTitle.Text = ""
    TabTitle.Font = Enum.Font.GothamMedium
    TabTitle.TextSize = 18
    TabTitle.TextColor3 = config.TextColor
    TabTitle.TextXAlignment = Enum.TextXAlignment.Left
    TabTitle.Parent = RightPanel

    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -20, 1, -55)
    TabContainer.Position = UDim2.new(0, 10, 0, 48)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = RightPanel

    Window.Main = Main
    Window.Sidebar = Sidebar
    Window.TabTitle = TabTitle
    Window.TabContainer = TabContainer
    Window.ScreenGui = ScreenGui

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

    print("[sqservices.me] UI Library loaded")
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
    Button.Size = UDim2.new(1, 0, 0, 34)
    Button.BackgroundColor3 = Color3.fromRGB(20, 28, 50)
    Button.BackgroundTransparency = 1
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
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
    ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 90, 160)
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
    ContentPadding.PaddingBottom = UDim.new(0, 12)
    ContentPadding.Parent = ContentFrame

    Tab.Container = ContentFrame
    Tab.Button = Button

    Button.MouseEnter:Connect(function()
        if self.CurrentTab ~= Tab then
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.55,
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
        BackgroundTransparency = 0.3,
        TextColor3 = self.Config.TextColor
    }):Play()
end

return Library
