--[[
    sqservices.me UI Library
    Version 4.0 — Clean • Smooth • Blue-dot reopen

    Same API as before:
        Library:CreateWindow(config)
        Window:CreateTab(name) -> Tab
        Tab:CreateButton / CreateToggle / CreateCheckbox / CreateSlider
        Library:CreateKeySystem(options)

    New:
        Tab:CreateSection(text), Tab:CreateLabel(text)
        Toggle / Checkbox / Slider return (Holder, API) where API has :Set(value) and :Get()
        Window:Toggle(), Window:Destroy()
        Config: ToggleKey (default RightShift), ShowIP (default true), Accent
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local Theme = {
    Bg           = Color3.fromRGB(14, 16, 22),
    Panel        = Color3.fromRGB(18, 21, 29),
    Element      = Color3.fromRGB(25, 29, 39),
    ElementHover = Color3.fromRGB(32, 37, 50),
    Stroke       = Color3.fromRGB(40, 46, 62),
    Accent       = Color3.fromRGB(64, 140, 255),
    Text         = Color3.fromRGB(232, 236, 245),
    SubText      = Color3.fromRGB(124, 134, 156),
    Off          = Color3.fromRGB(44, 50, 67),
}

local Defaults = {
    Title = "sqservices.me",
    Size = UDim2.new(0, 540, 0, 400),
    SidebarWidth = 132,
    ToggleKey = Enum.KeyCode.RightShift,
    ShowIP = true,
    Accent = Theme.Accent,
}

local function Tween(obj, props, time, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function New(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function Corner(r) return New("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function Stroke(color, transparency, thickness)
    return New("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function Padding(l, r, t, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
    })
end

local function IsPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

-- Shared hover/press feel for "card" elements
local function MakeInteractive(btn, strokeObj, accent)
    local scale = New("UIScale", {Scale = 1, Parent = btn})
    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.ElementHover}, 0.18)
        if strokeObj then Tween(strokeObj, {Color = accent, Transparency = 0.55}, 0.18) end
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.Element}, 0.18)
        if strokeObj then Tween(strokeObj, {Color = Theme.Stroke, Transparency = 0}, 0.18) end
        Tween(scale, {Scale = 1}, 0.15)
    end)
    btn.InputBegan:Connect(function(i)
        if IsPress(i) then Tween(scale, {Scale = 0.985}, 0.08) end
    end)
    btn.InputEnded:Connect(function(i)
        if IsPress(i) then Tween(scale, {Scale = 1}, 0.18, Enum.EasingStyle.Back) end
    end)
end

-------------------------------------------------
-- WINDOW
-------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    for k, v in pairs(Defaults) do
        if config[k] == nil then config[k] = v end
    end
    local Accent = config.Accent

    local Window = setmetatable({}, Library)
    Window.Config = config
    Window.Accent = Accent
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.IsHidden = false
    Window._connections = {}

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = PlayerGui:FindFirstChild("sqservicesUI")
    if old then old:Destroy() end

    local ScreenGui = New("ScreenGui", {
        Name = "sqservicesUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
        Parent = PlayerGui,
    })

    -- Main window (CanvasGroup lets the whole window fade/clip cleanly)
    local Main = New("CanvasGroup", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = config.Size,
        BackgroundColor3 = Theme.Bg,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Parent = ScreenGui,
    }, {Corner(14), Stroke(Theme.Stroke, 0.1, 1)})

    local MainScale = New("UIScale", {Scale = 0.94, Parent = Main})

    -- Top bar
    local TopBar = New("Frame", {
        Name = "TopBar", Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1, Parent = Main,
    })

    New("Frame", {
        Name = "Dot", Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 18, 0.5, -4),
        BackgroundColor3 = Accent, BorderSizePixel = 0, Parent = TopBar,
    }, {Corner(4)})

    New("TextLabel", {
        Name = "Title", Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1, Text = config.Title, Font = Enum.Font.GothamMedium,
        TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    local MinimizeBtn = New("TextButton", {
        Name = "Minimize", Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -40, 0.5, -14),
        BackgroundColor3 = Theme.Element, BackgroundTransparency = 1, AutoButtonColor = false,
        Text = "–", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.SubText,
        BorderSizePixel = 0, Parent = TopBar,
    }, {Corner(8)})

    MinimizeBtn.MouseEnter:Connect(function()
        Tween(MinimizeBtn, {BackgroundTransparency = 0, TextColor3 = Theme.Text}, 0.15)
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        Tween(MinimizeBtn, {BackgroundTransparency = 1, TextColor3 = Theme.SubText}, 0.15)
    end)

    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, Parent = TopBar,
    })

    -- Content area
    local Content = New("Frame", {
        Name = "Content", Size = UDim2.new(1, 0, 1, -70), Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1, Parent = Main,
    })

    local Sidebar = New("Frame", {
        Name = "Sidebar", Size = UDim2.new(0, config.SidebarWidth, 1, 0),
        BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.35,
        BorderSizePixel = 0, Parent = Content,
    }, {
        Padding(10, 10, 12, 10),
        New("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
    })

    New("Frame", {
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, config.SidebarWidth, 0, 0),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, Parent = Content,
    })

    local RightPanel = New("Frame", {
        Name = "RightPanel",
        Size = UDim2.new(1, -(config.SidebarWidth + 1), 1, 0),
        Position = UDim2.new(0, config.SidebarWidth + 1, 0, 0),
        BackgroundTransparency = 1, Parent = Content,
    })

    local TabTitle = New("TextLabel", {
        Name = "TabTitle", Size = UDim2.new(1, -28, 0, 22), Position = UDim2.new(0, 14, 0, 12),
        BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 15,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = RightPanel,
    })

    local TabContainer = New("Frame", {
        Name = "TabContainer", Size = UDim2.new(1, -24, 1, -48), Position = UDim2.new(0, 12, 0, 42),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = RightPanel,
    })

    -- Bottom bar
    local BottomBar = New("Frame", {
        Name = "BottomBar", Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 1, -28),
        BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.35,
        BorderSizePixel = 0, Parent = Main,
    })
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = BottomBar,
    })

    local TimeLabel = New("TextLabel", {
        Name = "TimeLabel", Size = UDim2.new(0.5, -16, 1, 0), Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1, Text = "--:--:--", Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = BottomBar,
    })
    local IPLabel = New("TextLabel", {
        Name = "IPLabel", Size = UDim2.new(0.5, -16, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right, Parent = BottomBar,
    })

    task.spawn(function()
        while Main and Main.Parent do
            local t = os.date("*t")
            TimeLabel.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
            task.wait(1)
        end
    end)

    if config.ShowIP then
        IPLabel.Text = "IP: ..."
        task.spawn(function()
            local ok, result = pcall(function() return game:HttpGet("https://api.ipify.org") end)
            IPLabel.Text = (ok and result) and ("IP: " .. result) or "IP: Unknown"
        end)
    end

    Window.Main = Main
    Window.Sidebar = Sidebar
    Window.TabTitle = TabTitle
    Window.TabContainer = TabContainer
    Window.ScreenGui = ScreenGui
    Window.BottomBar = BottomBar

    -------------------------------------------------
    -- BLUE DOT (reopen button)
    -------------------------------------------------
    local DotHolder = New("Frame", {
        Name = "OpenUI", Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -56, 1, -56),
        BackgroundTransparency = 1, Visible = false, ZIndex = 100, Parent = ScreenGui,
    })
    local DotScale = New("UIScale", {Scale = 0, Parent = DotHolder})

    local Glow = New("Frame", {
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0.5, -15, 0.5, -15),
        BackgroundColor3 = Accent, BackgroundTransparency = 0.8, BorderSizePixel = 0,
        ZIndex = 100, Parent = DotHolder,
    }, {Corner(15)})

    local Dot = New("TextButton", {
        Name = "Dot", Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7),
        BackgroundColor3 = Accent, AutoButtonColor = false, Text = "", BorderSizePixel = 0,
        ZIndex = 101, Parent = DotHolder,
    }, {Corner(7)})

    -- Hit area so the dot is easy to press
    local Hit = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
        ZIndex = 102, Parent = DotHolder,
    })

    TweenService:Create(Glow,
        TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0.5, -18, 0.5, -18), BackgroundTransparency = 0.92}
    ):Play()

    Hit.MouseEnter:Connect(function() Tween(DotScale, {Scale = 1.2}, 0.15) end)
    Hit.MouseLeave:Connect(function() Tween(DotScale, {Scale = 1}, 0.15) end)

    -------------------------------------------------
    -- HIDE / SHOW
    -------------------------------------------------
    local function HideUI()
        if Window.IsHidden then return end
        Window.IsHidden = true
        Tween(Main, {GroupTransparency = 1}, 0.2)
        Tween(MainScale, {Scale = 0.94}, 0.2)
        task.delay(0.2, function()
            if not Window.IsHidden then return end
            Main.Visible = false
            DotHolder.Visible = true
            DotScale.Scale = 0
            Tween(DotScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back)
        end)
    end

    local function ShowUI()
        if not Window.IsHidden then return end
        Window.IsHidden = false
        Tween(DotScale, {Scale = 0}, 0.15)
        task.delay(0.12, function()
            if Window.IsHidden then return end
            DotHolder.Visible = false
        end)
        Main.Visible = true
        Tween(Main, {GroupTransparency = 0}, 0.3)
        Tween(MainScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back)
    end

    Window.Hide, Window.Show = HideUI, ShowUI
    function Window:Toggle()
        if Window.IsHidden then ShowUI() else HideUI() end
    end
    function Window:Destroy()
        for _, c in ipairs(Window._connections) do c:Disconnect() end
        ScreenGui:Destroy()
    end

    MinimizeBtn.MouseButton1Click:Connect(HideUI)

    local function Track(conn) table.insert(Window._connections, conn) end

    Track(UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == config.ToggleKey then Window:Toggle() end
    end))

    -------------------------------------------------
    -- DRAGGING (window + dot)
    -------------------------------------------------
    local dragTarget, dragStart, startPos, moved = nil, nil, nil, false

    local function beginDrag(target, input)
        dragTarget, dragStart, startPos, moved = target, input.Position, target.Position, false
    end

    TopBar.InputBegan:Connect(function(input)
        if IsPress(input) then beginDrag(Main, input) end
    end)
    Hit.InputBegan:Connect(function(input)
        if IsPress(input) then beginDrag(DotHolder, input) end
    end)

    Track(UserInputService.InputChanged:Connect(function(input)
        if dragTarget and IsMove(input) then
            local d = input.Position - dragStart
            if d.Magnitude > 4 then moved = true end
            if moved then
                dragTarget.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end
    end))

    Track(UserInputService.InputEnded:Connect(function(input)
        if dragTarget and IsPress(input) then
            local wasDot = dragTarget == DotHolder
            local didMove = moved
            dragTarget = nil
            if wasDot and not didMove then ShowUI() end
        end
    end))

    -------------------------------------------------
    -- INTRO
    -------------------------------------------------
    Tween(Main, {GroupTransparency = 0}, 0.4)
    Tween(MainScale, {Scale = 1}, 0.5, Enum.EasingStyle.Back)

    print("[sqservices.me] UI Library v4.0 loaded")
    return Window
end

-------------------------------------------------
-- TABS
-------------------------------------------------
function Library:CreateTab(name)
    local window = self
    local Accent = self.Accent
    local Tab = {Name = name}

    local Button = New("TextButton", {
        Name = name, Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
        BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium,
        TextSize = 13, TextColor3 = Theme.SubText, Text = name,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #self.Tabs + 1,
        Parent = self.Sidebar,
    }, {Corner(8), Padding(14, 0, 0, 0)})

    local Bar = New("Frame", {
        Name = "Indicator", Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, -10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Accent, BorderSizePixel = 0,
        Parent = Button,
    }, {Corner(2)})
    -- bar sits just inside the sidebar edge
    Bar.Position = UDim2.new(0, -6, 0.5, 0)

    -- Page = CanvasGroup so a whole tab fades/slides as one piece
    local Page = New("CanvasGroup", {
        Name = name .. "_Page", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1, GroupTransparency = 1, Visible = false,
        Parent = self.TabContainer,
    })

    local Scroll = New("ScrollingFrame", {
        Name = name .. "_Content", Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
        ScrollBarImageColor3 = Accent, ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = Page,
    }, {
        New("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}),
        Padding(0, 6, 2, 12),
    })

    Tab.Container = Scroll
    Tab.Page = Page
    Tab.Button = Button
    Tab.Indicator = Bar

    Button.MouseEnter:Connect(function()
        if window.CurrentTab ~= Tab then
            Tween(Button, {BackgroundTransparency = 0.6, TextColor3 = Theme.Text}, 0.18)
        end
    end)
    Button.MouseLeave:Connect(function()
        if window.CurrentTab ~= Tab then
            Tween(Button, {BackgroundTransparency = 1, TextColor3 = Theme.SubText}, 0.18)
        end
    end)
    Button.MouseButton1Click:Connect(function() window:SelectTab(Tab) end)

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then self:SelectTab(Tab) end

    local function nextOrder()
        Tab._order = (Tab._order or 0) + 1
        return Tab._order
    end

    -- Section header
    function Tab:CreateSection(text)
        return New("TextLabel", {
            Name = "Section", Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
            Text = string.upper(text or "Section"), Font = Enum.Font.GothamBold, TextSize = 10,
            TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = nextOrder(), Parent = Scroll,
        }, {Padding(2, 0, 6, 0)})
    end

    -- Plain label
    function Tab:CreateLabel(text)
        local l = New("TextLabel", {
            Name = "Label", Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
            Text = text or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            LayoutOrder = nextOrder(), Parent = Scroll,
        }, {Padding(2, 0, 0, 0)})
        return l
    end

    -- Button
    function Tab:CreateButton(options)
        options = options or {}
        local callback = options.Callback or function() end

        local Btn = New("TextButton", {
            Name = options.Name or "Button", Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Element, BorderSizePixel = 0, AutoButtonColor = false,
            Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text,
            Text = options.Name or "Button", LayoutOrder = nextOrder(), Parent = Scroll,
        }, {Corner(9)})
        local st = Stroke(Theme.Stroke, 0, 1)
        st.Parent = Btn

        MakeInteractive(Btn, st, Accent)

        Btn.MouseButton1Click:Connect(function()
            -- little accent flash
            Btn.BackgroundColor3 = Accent
            Tween(Btn, {BackgroundColor3 = Theme.ElementHover}, 0.35)
            task.spawn(callback)
        end)

        return Btn
    end

    -- Toggle
    function Tab:CreateToggle(options)
        options = options or {}
        local callback = options.Callback or function() end
        local state = options.Default or false

        local Holder = New("TextButton", {
            Name = options.Name or "Toggle", Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Theme.Element, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "", LayoutOrder = nextOrder(), Parent = Scroll,
        }, {Corner(9)})
        local st = Stroke(Theme.Stroke, 0, 1)
        st.Parent = Holder
        MakeInteractive(Holder, st, Accent)

        New("TextLabel", {
            Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1, Text = options.Name or "Toggle", Font = Enum.Font.Gotham,
            TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Track = New("Frame", {
            Size = UDim2.new(0, 38, 0, 20), Position = UDim2.new(1, -52, 0.5, -10),
            BackgroundColor3 = state and Accent or Theme.Off, BorderSizePixel = 0, Parent = Holder,
        }, {Corner(10)})

        local Knob = New("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Color3.fromRGB(245, 248, 255), BorderSizePixel = 0, Parent = Track,
        }, {Corner(7)})

        local function render()
            Tween(Track, {BackgroundColor3 = state and Accent or Theme.Off}, 0.2)
            Tween(Knob, {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)},
                0.25, Enum.EasingStyle.Back)
        end

        local API = {}
        function API:Set(v, silent)
            state = v and true or false
            render()
            if not silent then task.spawn(callback, state) end
        end
        function API:Get() return state end

        Holder.MouseButton1Click:Connect(function() API:Set(not state) end)
        return Holder, API
    end

    -- Checkbox
    function Tab:CreateCheckbox(options)
        options = options or {}
        local callback = options.Callback or function() end
        local state = options.Default or false

        local Holder = New("TextButton", {
            Name = options.Name or "Checkbox", Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Theme.Element, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "", LayoutOrder = nextOrder(), Parent = Scroll,
        }, {Corner(9)})
        local st = Stroke(Theme.Stroke, 0, 1)
        st.Parent = Holder
        MakeInteractive(Holder, st, Accent)

        local Box = New("Frame", {
            Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 12, 0.5, -9),
            BackgroundColor3 = state and Accent or Theme.Off, BorderSizePixel = 0, Parent = Holder,
        }, {Corner(5)})

        local Check = New("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "✓",
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1),
            TextTransparency = state and 0 or 1, Parent = Box,
        })

        New("TextLabel", {
            Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 42, 0, 0),
            BackgroundTransparency = 1, Text = options.Name or "Checkbox", Font = Enum.Font.Gotham,
            TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local API = {}
        function API:Set(v, silent)
            state = v and true or false
            Tween(Box, {BackgroundColor3 = state and Accent or Theme.Off}, 0.18)
            Tween(Check, {TextTransparency = state and 0 or 1}, 0.18)
            if not silent then task.spawn(callback, state) end
        end
        function API:Get() return state end

        Holder.MouseButton1Click:Connect(function() API:Set(not state) end)
        return Holder, API
    end

    -- Slider
    function Tab:CreateSlider(options)
        options = options or {}
        local callback = options.Callback or function() end
        local min = options.Min or 0
        local max = options.Max or 100
        local inc = options.Increment or 1
        local value = math.clamp(options.Default or min, min, max)
        local name = options.Name or "Slider"

        local Holder = New("Frame", {
            Name = name, Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.Element,
            BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = Scroll,
        }, {Corner(9)})
        local st = Stroke(Theme.Stroke, 0, 1)
        st.Parent = Holder

        New("TextLabel", {
            Size = UDim2.new(1, -90, 0, 18), Position = UDim2.new(0, 14, 0, 8),
            BackgroundTransparency = 1, Text = name, Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder,
        })

        local ValueLabel = New("TextLabel", {
            Size = UDim2.new(0, 70, 0, 18), Position = UDim2.new(1, -84, 0, 8),
            BackgroundTransparency = 1, Text = tostring(value), Font = Enum.Font.GothamMedium,
            TextSize = 12, TextColor3 = Accent, TextXAlignment = Enum.TextXAlignment.Right,
            Parent = Holder,
        })

        local Track = New("Frame", {
            Size = UDim2.new(1, -28, 0, 4), Position = UDim2.new(0, 14, 0, 36),
            BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = Holder,
        }, {Corner(2)})

        local pct0 = (max == min) and 0 or (value - min) / (max - min)
        local Fill = New("Frame", {
            Size = UDim2.new(pct0, 0, 1, 0), BackgroundColor3 = Accent,
            BorderSizePixel = 0, Parent = Track,
        }, {Corner(2)})

        local Knob = New("Frame", {
            Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(pct0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(245, 248, 255),
            BorderSizePixel = 0, ZIndex = 2, Parent = Track,
        }, {Corner(6)})
        local KnobScale = New("UIScale", {Scale = 0.85, Parent = Knob})

        local function snap(v)
            v = math.floor(v / inc + 0.5) * inc
            return math.clamp(tonumber(string.format("%.6g", v)), min, max)
        end

        local function setValue(v, silent, instant)
            value = snap(v)
            local pct = (max == min) and 0 or (value - min) / (max - min)
            local t = instant and 0 or 0.08
            Tween(Fill, {Size = UDim2.new(pct, 0, 1, 0)}, t)
            Tween(Knob, {Position = UDim2.new(pct, 0, 0.5, 0)}, t)
            ValueLabel.Text = tostring(value)
            if not silent then task.spawn(callback, value) end
        end

        local dragging = false
        local function fromInput(input)
            local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
            setValue(min + (max - min) * rel)
        end

        Holder.InputBegan:Connect(function(input)
            if IsPress(input) then
                dragging = true
                Tween(KnobScale, {Scale = 1.15}, 0.12)
                Tween(st, {Color = Accent, Transparency = 0.55}, 0.15)
                fromInput(input)
            end
        end)
        Holder.MouseEnter:Connect(function() Tween(Holder, {BackgroundColor3 = Theme.ElementHover}, 0.18) end)
        Holder.MouseLeave:Connect(function()
            if not dragging then Tween(Holder, {BackgroundColor3 = Theme.Element}, 0.18) end
        end)

        local c1 = UserInputService.InputChanged:Connect(function(input)
            if dragging and IsMove(input) then fromInput(input) end
        end)
        local c2 = UserInputService.InputEnded:Connect(function(input)
            if dragging and IsPress(input) then
                dragging = false
                Tween(KnobScale, {Scale = 0.85}, 0.15)
                Tween(st, {Color = Theme.Stroke, Transparency = 0}, 0.2)
                Tween(Holder, {BackgroundColor3 = Theme.Element}, 0.18)
            end
        end)
        table.insert(window._connections, c1)
        table.insert(window._connections, c2)

        local API = {}
        function API:Set(v, silent) setValue(v, silent) end
        function API:Get() return value end

        return Holder, API
    end

    return Tab
end

-------------------------------------------------
-- SMOOTH TAB SWITCH
-------------------------------------------------
function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end
    local old = self.CurrentTab
    self.CurrentTab = tab
    self.TabTitle.Text = tab.Name

    if old then
        Tween(old.Button, {
            BackgroundTransparency = 1, TextColor3 = Theme.SubText,
        }, 0.22)
        Tween(old.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
        Tween(old.Page, {GroupTransparency = 1, Position = UDim2.new(0, 0, 0, -8)}, 0.15)
        task.delay(0.16, function()
            if self.CurrentTab ~= old then old.Page.Visible = false end
        end)
    end

    tab.Page.Visible = true
    tab.Page.Position = UDim2.new(0, 0, 0, 12)
    tab.Page.GroupTransparency = 1
    Tween(tab.Page, {GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, 0.35)

    tab.Button.BackgroundColor3 = self.Accent
    Tween(tab.Button, {BackgroundTransparency = 0.88, TextColor3 = Theme.Text}, 0.25)
    Tween(tab.Indicator, {Size = UDim2.new(0, 3, 0, 16)}, 0.3, Enum.EasingStyle.Back)
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
    local Accent = options.Accent or Theme.Accent

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = PlayerGui:FindFirstChild("sqservicesKeySystem")
    if old then old:Destroy() end

    local ScreenGui = New("ScreenGui", {
        Name = "sqservicesKeySystem", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
        IgnoreGuiInset = true, Parent = PlayerGui,
    })

    local Overlay = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0, Parent = ScreenGui,
    })
    Tween(Overlay, {BackgroundTransparency = 0.45}, 0.4)

    local Box = New("CanvasGroup", {
        Name = "KeyBox", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 360, 0, 214), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
        GroupTransparency = 1, Parent = Overlay,
    }, {Corner(14), Stroke(Theme.Stroke, 0.1, 1)})
    local BoxScale = New("UIScale", {Scale = 0.94, Parent = Box})
    Tween(Box, {GroupTransparency = 0}, 0.35)
    Tween(BoxScale, {Scale = 1}, 0.45, Enum.EasingStyle.Back)

    New("Frame", {
        Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 20, 0, 24),
        BackgroundColor3 = Accent, BorderSizePixel = 0, Parent = Box,
    }, {Corner(4)})

    New("TextLabel", {
        Size = UDim2.new(1, -60, 0, 22), Position = UDim2.new(0, 38, 0, 17),
        BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
    })

    local Note = New("TextLabel", {
        Size = UDim2.new(1, -40, 0, 16), Position = UDim2.new(0, 20, 0, 48),
        BackgroundTransparency = 1, Text = note, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
    })

    local TextBox = New("TextBox", {
        Name = "KeyInput", Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 76),
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0, PlaceholderText = "Enter key here...",
        PlaceholderColor3 = Theme.SubText, Text = "", Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = Theme.Text, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Box,
    }, {Corner(9), Padding(14, 14, 0, 0)})
    local boxStroke = Stroke(Theme.Stroke, 0, 1)
    boxStroke.Parent = TextBox
    TextBox.Focused:Connect(function() Tween(boxStroke, {Color = Accent, Transparency = 0.3}, 0.18) end)
    TextBox.FocusLost:Connect(function() Tween(boxStroke, {Color = Theme.Stroke, Transparency = 0}, 0.18) end)

    local Buttons = New("Frame", {
        Size = UDim2.new(1, -40, 0, 38), Position = UDim2.new(0, 20, 0, 136),
        BackgroundTransparency = 1, Parent = Box,
    }, {
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
    })

    local function makeBtn(text, primary)
        local b = New("TextButton", {
            Size = UDim2.new(0.5, -5, 1, 0),
            BackgroundColor3 = primary and Accent or Theme.Element, BorderSizePixel = 0,
            AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 13,
            TextColor3 = primary and Color3.new(1, 1, 1) or Theme.Text, Text = text, Parent = Buttons,
        }, {Corner(9)})
        local s = New("UIScale", {Scale = 1, Parent = b})
        local base = primary and Accent or Theme.Element
        local hover = primary and Accent:Lerp(Color3.new(1, 1, 1), 0.15) or Theme.ElementHover
        b.MouseEnter:Connect(function() Tween(b, {BackgroundColor3 = hover}, 0.15) end)
        b.MouseLeave:Connect(function() Tween(b, {BackgroundColor3 = base}, 0.15); Tween(s, {Scale = 1}, 0.15) end)
        b.InputBegan:Connect(function(i) if IsPress(i) then Tween(s, {Scale = 0.97}, 0.08) end end)
        b.InputEnded:Connect(function(i) if IsPress(i) then Tween(s, {Scale = 1}, 0.18, Enum.EasingStyle.Back) end end)
        return b
    end

    local Redeem = makeBtn("Redeem", true)
    local GetKey = makeBtn("Get Key", false)

    GetKey.MouseButton1Click:Connect(function()
        if setclipboard then pcall(setclipboard, tostring(link)) end
        GetKey.Text = "Copied!"
        task.delay(1.4, function()
            if GetKey and GetKey.Parent then GetKey.Text = "Get Key" end
        end)
    end)

    local function tryRedeem()
        local key = TextBox.Text:gsub("%s+", "")
        if key == "" then return end
        task.spawn(callback, key)
    end

    Redeem.MouseButton1Click:Connect(tryRedeem)
    TextBox.FocusLost:Connect(function(enter) if enter then tryRedeem() end end)

    local function shake()
        for i = 1, 3 do
            Tween(Box, {Position = UDim2.new(0.5, 7, 0.5, 0)}, 0.05)
            task.wait(0.05)
            Tween(Box, {Position = UDim2.new(0.5, -7, 0.5, 0)}, 0.05)
            task.wait(0.05)
        end
        Tween(Box, {Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.08)
    end

    return {
        Gui = ScreenGui,
        Destroy = function()
            Tween(Box, {GroupTransparency = 1}, 0.2)
            Tween(BoxScale, {Scale = 0.94}, 0.2)
            Tween(Overlay, {BackgroundTransparency = 1}, 0.25)
            task.delay(0.26, function() ScreenGui:Destroy() end)
        end,
        SetNote = function(text, isError)
            Note.Text = tostring(text)
            Note.TextColor3 = isError and Color3.fromRGB(255, 100, 100) or Theme.SubText
            if isError then task.spawn(shake) end
        end,
    }
end

return Library
