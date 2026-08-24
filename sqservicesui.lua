--[[
    sqservices.me UI Window
    Clean dark-blue movable window with left tabs + right tab title
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Configuration
local Config = {
    WindowSize = UDim2.new(0, 520, 0, 340),
    BackgroundColor = Color3.fromRGB(12, 16, 32),      -- deep dark blue
    AccentColor = Color3.fromRGB(40, 90, 180),
    TextColor = Color3.fromRGB(220, 230, 255),
    SubTextColor = Color3.fromRGB(140, 155, 190),
    CornerRadius = UDim.new(0, 10),
}

--// Create the main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "sqservicesUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

--// Main Window Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = Config.WindowSize
Main.Position = UDim2.new(0.5, -Config.WindowSize.X.Offset/2, 0.5, -Config.WindowSize.Y.Offset/2)
Main.BackgroundColor3 = Config.BackgroundColor
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = Config.CornerRadius
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(30, 45, 80)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.4
MainStroke.Parent = Main

--// Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundTransparency = 1
TopBar.Parent = Main

-- Title (robot / tech font)
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "sqservices.me"
Title.Font = Enum.Font.Code                    -- robotic / mono look
Title.TextSize = 16
Title.TextColor3 = Config.TextColor
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.Parent = TopBar

-- Divider under title
local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.Size = UDim2.new(1, -20, 0, 1)
Divider.Position = UDim2.new(0, 10, 1, -1)
Divider.BackgroundColor3 = Color3.fromRGB(35, 50, 90)
Divider.BorderSizePixel = 0
Divider.Parent = TopBar

--// Content Area
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -42)
Content.Position = UDim2.new(0, 0, 0, 42)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Left Sidebar (Tabs)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = Content

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = UDim.new(0, 6)
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 12)
SidebarPadding.PaddingLeft = UDim.new(0, 10)
SidebarPadding.Parent = Sidebar

-- Right Panel (shows current tab name)
local RightPanel = Instance.new("Frame")
RightPanel.Name = "RightPanel"
RightPanel.Size = UDim2.new(1, -140, 1, 0)
RightPanel.Position = UDim2.new(0, 140, 0, 0)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = Content

local TabTitle = Instance.new("TextLabel")
TabTitle.Name = "TabTitle"
TabTitle.Size = UDim2.new(1, -20, 0, 30)
TabTitle.Position = UDim2.new(0, 10, 0, 12)
TabTitle.BackgroundTransparency = 1
TabTitle.Text = "Home"
TabTitle.Font = Enum.Font.GothamMedium
TabTitle.TextSize = 18
TabTitle.TextColor3 = Config.TextColor
TabTitle.TextXAlignment = Enum.TextXAlignment.Left
TabTitle.Parent = RightPanel

--// Tab System
local Tabs = {
    {Name = "Home", LayoutOrder = 1},
    {Name = "Visuals", LayoutOrder = 2},
}

local CurrentTab = "Home"
local TabButtons = {}

local function CreateTabButton(tabData)
    local Button = Instance.new("TextButton")
    Button.Name = tabData.Name
    Button.Size = UDim2.new(1, -8, 0, 32)
    Button.BackgroundColor3 = Color3.fromRGB(20, 28, 50)
    Button.BackgroundTransparency = 1
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.Gotham               -- normal font
    Button.TextSize = 14
    Button.TextColor3 = Config.SubTextColor
    Button.Text = tabData.Name
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.LayoutOrder = tabData.LayoutOrder
    Button.Parent = Sidebar

    local ButtonPadding = Instance.new("UIPadding")
    ButtonPadding.PaddingLeft = UDim.new(0, 10)
    ButtonPadding.Parent = Button

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = Button

    -- Hover effect
    Button.MouseEnter:Connect(function()
        if CurrentTab ~= tabData.Name then
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.6,
                TextColor3 = Config.TextColor
            }):Play()
        end
    end)

    Button.MouseLeave:Connect(function()
        if CurrentTab ~= tabData.Name then
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
                TextColor3 = Config.SubTextColor
            }):Play()
        end
    end)

    Button.MouseButton1Click:Connect(function()
        -- Reset previous
        if TabButtons[CurrentTab] then
            local prev = TabButtons[CurrentTab]
            TweenService:Create(prev, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
                TextColor3 = Config.SubTextColor
            }):Play()
        end

        -- Set new
        CurrentTab = tabData.Name
        TabTitle.Text = tabData.Name

        TweenService:Create(Button, TweenInfo.new(0.15), {
            BackgroundTransparency = 0.35,
            TextColor3 = Config.TextColor
        }):Play()
    end)

    TabButtons[tabData.Name] = Button
    return Button
end

for _, tab in ipairs(Tabs) do
    CreateTabButton(tab)
end

-- Set default active tab
do
    local homeBtn = TabButtons["Home"]
    homeBtn.BackgroundTransparency = 0.35
    homeBtn.TextColor3 = Config.TextColor
end

--// Dragging System
local Dragging = false
local DragStart = nil
local StartPos = nil

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

print("[sqservices.me] UI loaded successfully")
