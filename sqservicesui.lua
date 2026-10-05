--[[
    sqservices.me UI Library  —  v5.0
    Glass cards • icon tabs • collapsible sections • live ESP preview • blue-dot reopen

    ─────────────── QUICK START ───────────────
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/333shop/sqservicesui/main/sqservicesui.lua"))()

    local Window = Library:CreateWindow({
        Title = "My Script",          -- sidebar name
        Subtitle = "v1.0",            -- small text under the name
        Logo = "M",                   -- letter in the logo badge (optional)
        ToggleKey = Enum.KeyCode.RightShift,
        Accent = Color3.fromRGB(110, 94, 240),   -- optional
        Size = UDim2.new(0, 600, 0, 430),        -- optional
    })

    local Tab = Window:CreateTab("Visuals", {
        Icon = "◉",                   -- any text/emoji, or "rbxassetid://123"
        Title = "Visuals",            -- big header (defaults to the tab name)
        Subtitle = "Box, name, distance",
    })

    local Section = Tab:CreateSection("Name & Box ESP")      -- collapsible

    local _, box = Section:CreateToggle({
        Name = "Box ESP", Desc = "2D box around each target", Icon = "▢",
        Default = true, Flag = "Box",
        Callback = function(v) print("Box", v) end,
    })

    ELEMENTS (work on a Section OR directly on a Tab):
        :CreateToggle   {Name, Desc, Icon, Default, Flag, Callback(bool)}
        :CreateCheckbox {Name, Desc, Default, Flag, Callback(bool)}
        :CreateSlider   {Name, Desc, Min, Max, Default, Step, Suffix, Flag, Callback(number)}
        :CreateButton   {Name, Desc, Color, Callback()}
        :CreateDropdown {Name, Desc, Options = {...}, Default, Flag, Callback(string)}
        :CreateColors   {Name, Desc, Colors = {Color3,...}, Default, Flag, Callback(Color3)}
        :CreateTextBox  {Name, Desc, Placeholder, Default, Flag, Callback(string)}
        :CreateLabel(text)
    Every element returns (Instance, API).  API:Set(v, silent)  API:Get()  API:OnChanged(fn)
    All values are also stored in Window.Flags[Flag].

    ESP PREVIEW PANEL (the little character on the right):
        local Preview = Window:CreateESPPreview()
        Preview:Bind("Box", boxAPI)          -- "Box" | "Name" | "Distance" | "Health" | "Highlight"
        Preview:BindColor(colorsAPI)         -- tints the preview
        -- tapping things in the preview toggles the bound toggles, and vice-versa

    WINDOW:  Window:Toggle() / :Hide() / :Show() / :Destroy() / :OnDestroy(fn)
    KEY SYSTEM:  Library:CreateKeySystem({Title, Note, Link, Callback(key)}) -> {Destroy, SetNote(text, isError)}
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library
Library.Version = "5.0"

local Theme = {
    Bg        = Color3.fromRGB(16, 17, 28),
    Panel     = Color3.fromRGB(20, 21, 35),
    Card      = Color3.fromRGB(25, 26, 43),
    CardHover = Color3.fromRGB(32, 33, 56),
    Stroke    = Color3.fromRGB(48, 50, 80),
    Accent    = Color3.fromRGB(110, 94, 240),
    Accent2   = Color3.fromRGB(66, 112, 235),
    Dot       = Color3.fromRGB(64, 140, 255),
    Text      = Color3.fromRGB(240, 241, 250),
    Sub       = Color3.fromRGB(135, 138, 172),
    Off       = Color3.fromRGB(52, 54, 82),
    Danger    = Color3.fromRGB(255, 110, 120),
}

local Defaults = {
    Title = "sqservices.me",
    Subtitle = "UI v5",
    Size = UDim2.new(0, 600, 0, 430),
    SidebarWidth = 170,
    ToggleKey = Enum.KeyCode.RightShift,
}

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function Tween(obj, props, time, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
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
        Color = color, Transparency = transparency or 0,
        Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function Pad(l, r, t, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
    })
end
local function Gradient(c1, c2, rot)
    return New("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 0})
end
local function List(padding)
    return New("UIListLayout", {Padding = UDim.new(0, padding or 0), SortOrder = Enum.SortOrder.LayoutOrder})
end
local function IsPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function IsMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end
local function Round(v, step)
    v = math.floor(v / step + 0.5) * step
    return tonumber(string.format("%.6g", v))
end

local function GuiParent()
    local ok, gui = pcall(function() return gethui and gethui() end)
    if ok and gui then return gui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function HoverCard(T, card, stroke)
    local scale = New("UIScale", {Scale = 1, Parent = card})
    card.MouseEnter:Connect(function()
        Tween(card, {BackgroundColor3 = T.CardHover}, 0.18)
        if stroke then Tween(stroke, {Color = T.Accent, Transparency = 0.6}, 0.18) end
    end)
    card.MouseLeave:Connect(function()
        Tween(card, {BackgroundColor3 = T.Card}, 0.18)
        if stroke then Tween(stroke, {Color = T.Stroke, Transparency = 0}, 0.18) end
        Tween(scale, {Scale = 1}, 0.15)
    end)
    card.InputBegan:Connect(function(i) if IsPress(i) then Tween(scale, {Scale = 0.988}, 0.08) end end)
    card.InputEnded:Connect(function(i) if IsPress(i) then Tween(scale, {Scale = 1}, 0.18, Enum.EasingStyle.Back) end end)
end

-- icon: text glyph or rbxassetid
local function MakeIcon(parent, icon, size, color, props)
    props = props or {}
    if type(icon) == "string" and icon:find("^rbxasset") then
        return New("ImageLabel", {
            Size = props.Size or UDim2.new(0, size, 0, size), Position = props.Position,
            BackgroundTransparency = 1, Image = icon, ImageColor3 = color, Parent = parent,
        })
    end
    return New("TextLabel", {
        Size = props.Size or UDim2.new(0, size, 0, size), Position = props.Position,
        BackgroundTransparency = 1, Text = icon or "•", Font = Enum.Font.GothamBold,
        TextSize = size - 2, TextColor3 = color, Parent = parent,
    })
end

local function ColorProp(icon) return icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3" end

-------------------------------------------------
-- ELEMENT BUILDERS (shared by Tab and Section)
-------------------------------------------------
local function AttachElements(obj, window, body, nextOrder)
    local T = window.Theme

    local function Card(height, clickable)
        local props = {
            Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.Card, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Parent = body,
        }
        if clickable then props.Text = "" props.AutoButtonColor = false end
        local card = New(clickable and "TextButton" or "Frame", props, {Corner(12)})
        local st = Stroke(T.Stroke, 0, 1)
        st.Parent = card
        HoverCard(T, card, st)
        return card, st
    end

    local function CardText(card, name, desc, x, rightReserve, height)
        local hasDesc = desc and desc ~= ""
        New("TextLabel", {
            Size = UDim2.new(1, -(x + rightReserve), 0, 18),
            Position = UDim2.new(0, x, 0, hasDesc and 10 or (height - 18) / 2),
            BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
        })
        if hasDesc then
            New("TextLabel", {
                Size = UDim2.new(1, -(x + rightReserve), 0, 14), Position = UDim2.new(0, x, 0, 29),
                BackgroundTransparency = 1, Text = desc, Font = Enum.Font.Gotham, TextSize = 11,
                TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
            })
        end
    end

    local function CardIcon(card, icon)
        local ib = New("Frame", {
            Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 14, 0.5, -16),
            BackgroundColor3 = T.CardHover, BorderSizePixel = 0, Parent = card,
        }, {Corner(9), Stroke(T.Stroke, 0.2, 1)})
        MakeIcon(ib, icon, 16, T.Sub, {Size = UDim2.new(1, 0, 1, 0)})
        return 58
    end

    local function MakeAPI(o, initial)
        local api = {_listeners = {}}
        function api:OnChanged(fn) table.insert(self._listeners, fn) end
        function api:_fire(v, silent)
            if o.Flag then window.Flags[o.Flag] = v end
            for _, fn in ipairs(self._listeners) do task.spawn(fn, v) end
            if not silent and o.Callback then task.spawn(o.Callback, v) end
        end
        if o.Flag then window.Flags[o.Flag] = initial end
        return api
    end

    local function Name(o) return o.Name or o.Title or "Element" end
    local function Desc(o) return o.Desc or o.Description end

    -- Toggle
    function obj:CreateToggle(o)
        o = o or {}
        local state = o.Default and true or false
        local height = Desc(o) and 56 or 44
        local card = Card(height, true)
        local x = o.Icon and CardIcon(card, o.Icon) or 14
        CardText(card, Name(o), Desc(o), x, 76, height)

        local Track = New("Frame", {
            Size = UDim2.new(0, 44, 0, 24), Position = UDim2.new(1, -58, 0.5, -12),
            BackgroundColor3 = state and T.Accent or T.Off, BorderSizePixel = 0, Parent = card,
        }, {Corner(12)})
        local Knob = New("Frame", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = Color3.fromRGB(240, 241, 252), BorderSizePixel = 0, Parent = Track,
        }, {Corner(9)})

        local api = MakeAPI(o, state)
        api.Instance = card
        function api:Get() return state end
        function api:Set(v, silent)
            state = v and true or false
            Tween(Track, {BackgroundColor3 = state and T.Accent or T.Off}, 0.2)
            Tween(Knob, {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)},
                0.28, Enum.EasingStyle.Back)
            api:_fire(state, silent)
        end
        card.MouseButton1Click:Connect(function() api:Set(not state) end)
        return card, api
    end

    -- Checkbox
    function obj:CreateCheckbox(o)
        o = o or {}
        local state = o.Default and true or false
        local height = Desc(o) and 56 or 44
        local card = Card(height, true)

        local Box = New("Frame", {
            Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 14, 0.5, -10),
            BackgroundColor3 = state and T.Accent or T.Off, BorderSizePixel = 0, Parent = card,
        }, {Corner(6)})
        local Check = New("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "✓", Font = Enum.Font.GothamBold,
            TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextTransparency = state and 0 or 1, Parent = Box,
        })
        CardText(card, Name(o), Desc(o), 46, 16, height)

        local api = MakeAPI(o, state)
        api.Instance = card
        function api:Get() return state end
        function api:Set(v, silent)
            state = v and true or false
            Tween(Box, {BackgroundColor3 = state and T.Accent or T.Off}, 0.18)
            Tween(Check, {TextTransparency = state and 0 or 1}, 0.18)
            api:_fire(state, silent)
        end
        card.MouseButton1Click:Connect(function() api:Set(not state) end)
        return card, api
    end

    -- Button
    function obj:CreateButton(o)
        o = o or {}
        local height = Desc(o) and 56 or 44
        local card = Card(height, true)
        CardText(card, Name(o), Desc(o), 14, 16, height)
        if o.Color then
            for _, c in ipairs(card:GetChildren()) do
                if c:IsA("TextLabel") and c.Font == Enum.Font.GothamBold then c.TextColor3 = o.Color end
            end
        end
        card.MouseButton1Click:Connect(function()
            card.BackgroundColor3 = T.Accent
            Tween(card, {BackgroundColor3 = T.CardHover}, 0.35)
            if o.Callback then task.spawn(o.Callback) end
        end)
        return card, {Instance = card}
    end

    -- Slider
    function obj:CreateSlider(o)
        o = o or {}
        local min, max, step = o.Min or 0, o.Max or 100, o.Step or o.Increment or 1
        local value = math.clamp(o.Default or min, min, max)
        local card = Card(68, false)
        CardText(card, Name(o), Desc(o), 14, 110, 68)

        local ValueLabel = New("TextLabel", {
            Size = UDim2.new(0, 100, 0, 18), Position = UDim2.new(1, -114, 0, 10), BackgroundTransparency = 1,
            Text = tostring(value) .. (o.Suffix or ""), Font = Enum.Font.GothamBold, TextSize = 12,
            TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
        })
        local Track = New("Frame", {
            Size = UDim2.new(1, -28, 0, 5), Position = UDim2.new(0, 14, 0, 54),
            BackgroundColor3 = T.Off, BorderSizePixel = 0, Parent = card,
        }, {Corner(3)})
        local p0 = (max == min) and 0 or (value - min) / (max - min)
        local Fill = New("Frame", {
            Size = UDim2.new(p0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = Track,
        }, {Corner(3), Gradient(T.Accent, T.Accent2, 0)})
        local Knob = New("Frame", {
            Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(p0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(240, 241, 252),
            BorderSizePixel = 0, ZIndex = 2, Parent = Track,
        }, {Corner(7)})
        local KnobScale = New("UIScale", {Scale = 0.85, Parent = Knob})

        local api = MakeAPI(o, value)
        api.Instance = card
        function api:Get() return value end
        function api:Set(v, silent)
            value = math.clamp(Round(v, step), min, max)
            local p = (max == min) and 0 or (value - min) / (max - min)
            Tween(Fill, {Size = UDim2.new(p, 0, 1, 0)}, 0.08)
            Tween(Knob, {Position = UDim2.new(p, 0, 0.5, 0)}, 0.08)
            ValueLabel.Text = tostring(value) .. (o.Suffix or "")
            api:_fire(value, silent)
        end

        local dragging = false
        local function fromInput(i)
            local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
            api:Set(min + (max - min) * rel)
        end
        card.InputBegan:Connect(function(i)
            if IsPress(i) then
                dragging = true
                Tween(KnobScale, {Scale = 1.15}, 0.12)
                fromInput(i)
            end
        end)
        window:_track(UserInputService.InputChanged:Connect(function(i)
            if dragging and IsMove(i) then fromInput(i) end
        end))
        window:_track(UserInputService.InputEnded:Connect(function(i)
            if dragging and IsPress(i) then
                dragging = false
                Tween(KnobScale, {Scale = 0.85}, 0.15)
            end
        end))
        return card, api
    end

    -- Color swatches
    function obj:CreateColors(o)
        o = o or {}
        local colors = o.Colors or {T.Accent, T.Accent2, Color3.fromRGB(255, 75, 90), Color3.fromRGB(80, 230, 130), Color3.new(1, 1, 1)}
        local current = o.Default or colors[1]
        local height = Desc(o) and 56 or 44
        local card = Card(height, false)
        CardText(card, Name(o), Desc(o), 14, #colors * 27 + 24, height)

        local row = New("Frame", {
            Size = UDim2.new(0, #colors * 27, 0, 24), Position = UDim2.new(1, -(#colors * 27 + 14), 0.5, -12),
            BackgroundTransparency = 1, Parent = card,
        }, {New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7),
            HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center,
        })})

        local api = MakeAPI(o, current)
        api.Instance = card
        local swatches = {}
        function api:Get() return current end
        function api:Set(c, silent)
            current = c
            for _, s in ipairs(swatches) do
                Tween(s.Stroke, {Transparency = (s.Color == c) and 0 or 1}, 0.15)
            end
            api:_fire(c, silent)
        end
        for _, c in ipairs(colors) do
            local sw = New("TextButton", {
                Size = UDim2.new(0, 20, 0, 20), BackgroundColor3 = c, Text = "", AutoButtonColor = false,
                BorderSizePixel = 0, Parent = row,
            }, {Corner(10)})
            local s = Stroke(Color3.new(1, 1, 1), c == current and 0 or 1, 2)
            s.Parent = sw
            table.insert(swatches, {Color = c, Stroke = s})
            sw.MouseEnter:Connect(function() Tween(sw, {Size = UDim2.new(0, 24, 0, 24)}, 0.12) end)
            sw.MouseLeave:Connect(function() Tween(sw, {Size = UDim2.new(0, 20, 0, 20)}, 0.12) end)
            sw.MouseButton1Click:Connect(function() api:Set(c) end)
        end
        return card, api
    end

    -- Dropdown
    function obj:CreateDropdown(o)
        o = o or {}
        local options = o.Options or {}
        local current = o.Default or options[1]
        local height = Desc(o) and 56 or 44

        local Holder = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            LayoutOrder = nextOrder(), Parent = body,
        }, {List(6)})

        local Head = New("TextButton", {
            Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.Card, BorderSizePixel = 0, Text = "",
            AutoButtonColor = false, LayoutOrder = 0, Parent = Holder,
        }, {Corner(12)})
        local st = Stroke(T.Stroke, 0, 1)
        st.Parent = Head
        HoverCard(T, Head, st)
        CardText(Head, Name(o), Desc(o), 14, 150, height)

        local ValueLabel = New("TextLabel", {
            Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(1, -150, 0, 0), BackgroundTransparency = 1,
            Text = tostring(current or "-"), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Accent,
            TextXAlignment = Enum.TextXAlignment.Right, Parent = Head,
        })
        local Arrow = New("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -26, 0, 0), BackgroundTransparency = 1,
            Text = "▾", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Sub, Parent = Head,
        })

        local ListFrame = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            Visible = false, LayoutOrder = 1, Parent = Holder,
        }, {List(4), Pad(10, 0, 0, 0)})

        local api = MakeAPI(o, current)
        api.Instance = Holder
        function api:Get() return current end
        function api:Set(v, silent)
            current = v
            ValueLabel.Text = tostring(v)
            api:_fire(v, silent)
        end
        for _, opt in ipairs(options) do
            local b = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Text = tostring(opt),
                Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.Sub, AutoButtonColor = false,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = ListFrame,
            }, {Corner(9), Pad(12, 0, 0, 0)})
            b.MouseEnter:Connect(function() Tween(b, {BackgroundColor3 = T.CardHover, TextColor3 = T.Text}, 0.12) end)
            b.MouseLeave:Connect(function() Tween(b, {BackgroundColor3 = T.Panel, TextColor3 = T.Sub}, 0.12) end)
            b.MouseButton1Click:Connect(function()
                api:Set(opt)
                ListFrame.Visible = false
                Arrow.Text = "▾"
            end)
        end
        Head.MouseButton1Click:Connect(function()
            ListFrame.Visible = not ListFrame.Visible
            Arrow.Text = ListFrame.Visible and "▴" or "▾"
        end)
        return Holder, api
    end

    -- TextBox
    function obj:CreateTextBox(o)
        o = o or {}
        local height = Desc(o) and 56 or 44
        local card = Card(height, false)
        CardText(card, Name(o), Desc(o), 14, 176, height)
        local tb = New("TextBox", {
            Size = UDim2.new(0, 150, 0, 28), Position = UDim2.new(1, -164, 0.5, -14),
            BackgroundColor3 = T.Panel, BorderSizePixel = 0, Text = o.Default or "",
            PlaceholderText = o.Placeholder or "...", PlaceholderColor3 = T.Sub, Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = T.Text, ClearTextOnFocus = false, Parent = card,
        }, {Corner(8), Pad(10, 10, 0, 0)})
        local s = Stroke(T.Stroke, 0, 1)
        s.Parent = tb
        tb.Focused:Connect(function() Tween(s, {Color = T.Accent, Transparency = 0.3}, 0.18) end)

        local api = MakeAPI(o, tb.Text)
        api.Instance = card
        function api:Get() return tb.Text end
        function api:Set(v, silent)
            tb.Text = tostring(v)
            api:_fire(tb.Text, silent)
        end
        tb.FocusLost:Connect(function()
            Tween(s, {Color = T.Stroke, Transparency = 0}, 0.18)
            api:_fire(tb.Text, false)
        end)
        return card, api
    end

    -- Label
    function obj:CreateLabel(text)
        return New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = text or "", Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            LayoutOrder = nextOrder(), Parent = body,
        }, {Pad(2, 0, 0, 0)})
    end
end

-------------------------------------------------
-- WINDOW
-------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    for k, v in pairs(Defaults) do
        if config[k] == nil then config[k] = v end
    end

    local T = {}
    for k, v in pairs(Theme) do T[k] = v end
    if config.Accent then T.Accent = config.Accent end
    if config.Accent2 then T.Accent2 = config.Accent2 end
    if config.DotColor then T.Dot = config.DotColor end

    local Window = setmetatable({}, Library)
    Window.Config = config
    Window.Theme = T
    Window.Tabs = {}
    Window.Flags = {}
    Window.CurrentTab = nil
    Window.IsHidden = false
    Window._conns = {}
    Window._groups = {}
    Window._onDestroy = {}

    function Window:_track(c)
        table.insert(self._conns, c)
        return c
    end

    local Parent = GuiParent()
    local old = Parent:FindFirstChild("sqservicesUI")
    if old then old:Destroy() end

    local ScreenGui = New("ScreenGui", {
        Name = "sqservicesUI", ResetOnSpawn = false, DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, Parent = Parent,
    })

    local MainW, MainH = config.Size.X.Offset, config.Size.Y.Offset
    local SideW = config.SidebarWidth

    local Container = New("Frame", {
        Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, MainW, 0, MainH), BackgroundTransparency = 1, Parent = ScreenGui,
    })
    local WinScale = New("UIScale", {Scale = 1, Parent = Container})
    Window._totalW = MainW

    local function FitScale()
        local cam = workspace.CurrentCamera
        if not cam then return 1 end
        local vp = cam.ViewportSize
        return math.clamp(math.min((vp.X - 30) / Window._totalW, (vp.Y - 30) / MainH), 0.5, 1)
    end

    local Main = New("CanvasGroup", {
        Name = "Main", Size = UDim2.new(0, MainW, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.03, BorderSizePixel = 0, GroupTransparency = 1, Parent = Container,
    }, {
        Corner(16), Stroke(T.Stroke, 0.1, 1),
        Gradient(Color3.fromRGB(24, 24, 44), Color3.fromRGB(13, 14, 24), 90),
    })
    table.insert(Window._groups, Main)

    -- Sidebar
    local Sidebar = New("Frame", {
        Name = "Sidebar", Size = UDim2.new(0, SideW, 1, 0), BackgroundColor3 = T.Panel,
        BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = Main,
    })
    New("Frame", {
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = T.Stroke,
        BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = Sidebar,
    })

    local Logo = New("Frame", {Name = "Logo", Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Parent = Sidebar})
    local Badge = New("Frame", {
        Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Parent = Logo,
    }, {Corner(10), Gradient(T.Accent, T.Accent2, 45)})
    New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = config.Logo or string.upper(string.sub(config.Title, 1, 1)),
        Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), Parent = Badge,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -62, 0, 18), Position = UDim2.new(0, 56, 0, 14), BackgroundTransparency = 1,
        Text = config.Title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Logo,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -62, 0, 14), Position = UDim2.new(0, 56, 0, 31), BackgroundTransparency = 1,
        Text = config.Subtitle, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.Sub,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = Logo,
    })

    local TabList = New("Frame", {
        Size = UDim2.new(1, 0, 1, -70), Position = UDim2.new(0, 0, 0, 66), BackgroundTransparency = 1, Parent = Sidebar,
    }, {Pad(10, 10, 0, 0), List(5)})

    -- Header
    local Header = New("Frame", {
        Name = "Header", Size = UDim2.new(1, -SideW, 0, 62), Position = UDim2.new(0, SideW, 0, 0),
        BackgroundTransparency = 1, Parent = Main,
    })
    local HeaderTitle = New("TextLabel", {
        Size = UDim2.new(1, -120, 0, 24), Position = UDim2.new(0, 22, 0, 12), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.GothamBold, TextSize = 19, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })
    local HeaderSub = New("TextLabel", {
        Size = UDim2.new(1, -120, 0, 14), Position = UDim2.new(0, 22, 0, 37), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })

    local function CircleBtn(text, xOff)
        local b = New("TextButton", {
            Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, xOff, 0, 18), BackgroundColor3 = T.Card,
            AutoButtonColor = false, Text = text, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.Sub,
            BorderSizePixel = 0, Parent = Header,
        }, {Corner(13), Stroke(T.Stroke, 0.3, 1)})
        b.MouseEnter:Connect(function() Tween(b, {BackgroundColor3 = T.CardHover, TextColor3 = T.Text}, 0.15) end)
        b.MouseLeave:Connect(function() Tween(b, {BackgroundColor3 = T.Card, TextColor3 = T.Sub}, 0.15) end)
        return b
    end
    local MinBtn = CircleBtn("–", -70)
    local CloseBtn = CircleBtn("✕", -38)

    local PageHolder = New("Frame", {
        Name = "Pages", Size = UDim2.new(1, -(SideW + 24), 1, -76), Position = UDim2.new(0, SideW + 12, 0, 66),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
    })

    Window.Main, Window.Container, Window.ScreenGui = Main, Container, ScreenGui
    Window.Sidebar, Window.TabList, Window.PageHolder = Sidebar, TabList, PageHolder

    -------------------------------------------------
    -- BLUE DOT
    -------------------------------------------------
    local DotHolder = New("Frame", {
        Name = "OpenUI", Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(1, -56, 1, -56),
        BackgroundTransparency = 1, Visible = false, ZIndex = 100, Parent = ScreenGui,
    })
    local DotScale = New("UIScale", {Scale = 0, Parent = DotHolder})
    local Glow = New("Frame", {
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0.5, -15, 0.5, -15), BackgroundColor3 = T.Dot,
        BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 100, Parent = DotHolder,
    }, {Corner(15)})
    New("Frame", {
        Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7), BackgroundColor3 = T.Dot,
        BorderSizePixel = 0, ZIndex = 101, Parent = DotHolder,
    }, {Corner(7)})
    local DotHit = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 102, Parent = DotHolder,
    })
    TweenService:Create(Glow,
        TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0.5, -18, 0.5, -18), BackgroundTransparency = 0.92}
    ):Play()
    DotHit.MouseEnter:Connect(function() Tween(DotScale, {Scale = 1.2}, 0.15) end)
    DotHit.MouseLeave:Connect(function() Tween(DotScale, {Scale = 1}, 0.15) end)

    local function SetGroups(t, time)
        for _, g in ipairs(Window._groups) do Tween(g, {GroupTransparency = t}, time) end
    end

    local function HideUI()
        if Window.IsHidden then return end
        Window.IsHidden = true
        SetGroups(1, 0.2)
        Tween(WinScale, {Scale = FitScale() * 0.94}, 0.2)
        task.delay(0.2, function()
            if not Window.IsHidden then return end
            Container.Visible = false
            DotHolder.Visible = true
            DotScale.Scale = 0
            Tween(DotScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back)
        end)
    end

    local function ShowUI()
        if not Window.IsHidden then return end
        Window.IsHidden = false
        Tween(DotScale, {Scale = 0}, 0.15)
        task.delay(0.12, function() if not Window.IsHidden then DotHolder.Visible = false end end)
        Container.Visible = true
        SetGroups(0, 0.3)
        Tween(WinScale, {Scale = FitScale()}, 0.35, Enum.EasingStyle.Back)
    end

    Window.Hide, Window.Show = HideUI, ShowUI
    function Window:Toggle()
        if Window.IsHidden then ShowUI() else HideUI() end
    end
    function Window:OnDestroy(fn) table.insert(Window._onDestroy, fn) end
    function Window:Destroy()
        for _, fn in ipairs(Window._onDestroy) do pcall(fn) end
        for _, c in ipairs(Window._conns) do pcall(function() c:Disconnect() end) end
        ScreenGui:Destroy()
    end

    MinBtn.MouseButton1Click:Connect(HideUI)
    CloseBtn.MouseButton1Click:Connect(function() Window:Destroy() end)

    Window:_track(UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == config.ToggleKey then Window:Toggle() end
    end))

    -------------------------------------------------
    -- DRAGGING
    -------------------------------------------------
    local dragTarget, dragStart, startPos, moved = nil, nil, nil, false
    local function beginDrag(target, input)
        dragTarget, dragStart, startPos, moved = target, input.Position, target.Position, false
    end
    Header.InputBegan:Connect(function(i) if IsPress(i) then beginDrag(Container, i) end end)
    Logo.InputBegan:Connect(function(i) if IsPress(i) then beginDrag(Container, i) end end)
    DotHit.InputBegan:Connect(function(i) if IsPress(i) then beginDrag(DotHolder, i) end end)

    Window:_track(UserInputService.InputChanged:Connect(function(i)
        if dragTarget and IsMove(i) then
            local d = i.Position - dragStart
            if d.Magnitude > 4 then moved = true end
            if moved then
                dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end))
    Window:_track(UserInputService.InputEnded:Connect(function(i)
        if dragTarget and IsPress(i) then
            local wasDot, didMove = dragTarget == DotHolder, moved
            dragTarget = nil
            if wasDot and not didMove then ShowUI() end
        end
    end))

    Window._headerTitle, Window._headerSub = HeaderTitle, HeaderSub
    Window._fitScale, Window._winScale = FitScale, WinScale

    -- Intro
    WinScale.Scale = FitScale() * 0.94
    SetGroups(0, 0.4)
    Tween(WinScale, {Scale = FitScale()}, 0.5, Enum.EasingStyle.Back)

    print("[sqservices.me] UI Library v" .. Library.Version .. " loaded")
    return Window
end

-------------------------------------------------
-- TABS
-------------------------------------------------
function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end
    local T = self.Theme
    local old = self.CurrentTab
    self.CurrentTab = tab
    self._headerTitle.Text = tab.Title
    self._headerSub.Text = tab.Subtitle

    if old then
        Tween(old.Button, {BackgroundTransparency = 1}, 0.22)
        Tween(old.Icon, {[ColorProp(old.Icon)] = T.Sub}, 0.22)
        Tween(old.Label, {TextColor3 = T.Sub}, 0.22)
        Tween(old.Page, {GroupTransparency = 1, Position = UDim2.new(0, 0, 0, -8)}, 0.15)
        task.delay(0.16, function()
            if self.CurrentTab ~= old then old.Page.Visible = false end
        end)
    end

    tab.Page.Visible = true
    tab.Page.Position = UDim2.new(0, 0, 0, 12)
    tab.Page.GroupTransparency = 1
    Tween(tab.Page, {GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, 0.35)
    Tween(tab.Button, {BackgroundTransparency = 0.05}, 0.25)
    Tween(tab.Icon, {[ColorProp(tab.Icon)] = Color3.new(1, 1, 1)}, 0.25)
    Tween(tab.Label, {TextColor3 = Color3.new(1, 1, 1)}, 0.25)
end

function Library:CreateTab(name, options)
    -- supports CreateTab("Name") and CreateTab("Name", {Icon=, Title=, Subtitle=})
    if type(options) ~= "table" then options = {} end
    local window = self
    local T = self.Theme
    local Tab = {
        Name = name, Title = options.Title or name, Subtitle = options.Subtitle or "",
    }

    local Button = New("TextButton", {
        Name = name, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1, AutoButtonColor = false, Text = "", BorderSizePixel = 0,
        LayoutOrder = #self.Tabs + 1, Parent = self.TabList,
    }, {Corner(10), Gradient(T.Accent, T.Accent2, 0)})
    Tab.Icon = MakeIcon(Button, options.Icon or string.sub(name, 1, 1), 17, T.Sub,
        {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 12, 0.5, -11)})
    Tab.Label = New("TextLabel", {
        Size = UDim2.new(1, -44, 1, 0), Position = UDim2.new(0, 42, 0, 0), BackgroundTransparency = 1, Text = name,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = Button,
    })
    Tab.Button = Button

    Button.MouseEnter:Connect(function()
        if window.CurrentTab ~= Tab then
            Tween(Tab.Label, {TextColor3 = T.Text}, 0.15)
            Tween(Tab.Icon, {[ColorProp(Tab.Icon)] = T.Text}, 0.15)
        end
    end)
    Button.MouseLeave:Connect(function()
        if window.CurrentTab ~= Tab then
            Tween(Tab.Label, {TextColor3 = T.Sub}, 0.15)
            Tween(Tab.Icon, {[ColorProp(Tab.Icon)] = T.Sub}, 0.15)
        end
    end)
    Button.MouseButton1Click:Connect(function() window:SelectTab(Tab) end)

    Tab.Page = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false,
        Parent = self.PageHolder,
    })
    local Scroll = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent, ScrollBarImageTransparency = 0.4, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = Tab.Page,
    }, {List(12), Pad(0, 8, 2, 14)})
    Tab.Container = Scroll

    local order = 0
    local function nextOrder()
        order = order + 1
        return order
    end

    AttachElements(Tab, window, Scroll, nextOrder)

    -- Collapsible section
    function Tab:CreateSection(text)
        text = text or "Section"
        local Section = {}
        local Wrap = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            LayoutOrder = nextOrder(), Parent = Scroll,
        }, {List(8)})

        local Head = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            LayoutOrder = 0, Parent = Wrap,
        })
        New("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
            Text = string.upper(text), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.Sub, Parent = Head,
        })
        local w = TextService:GetTextSize(string.upper(text), 10, Enum.Font.GothamBold, Vector2.new(400, 20)).X
        New("Frame", {
            Size = UDim2.new(1, -(w + 10 + 28), 0, 1), Position = UDim2.new(0, w + 10, 0.5, 0),
            BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = Head,
        })
        local Chev = New("TextLabel", {
            Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -18, 0, 0), BackgroundTransparency = 1,
            Text = "▾", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Sub, Parent = Head,
        })
        local Body = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            LayoutOrder = 1, Parent = Wrap,
        }, {List(8)})
        Head.MouseButton1Click:Connect(function()
            Body.Visible = not Body.Visible
            Chev.Text = Body.Visible and "▾" or "▸"
        end)

        local sOrder = 0
        AttachElements(Section, window, Body, function()
            sOrder = sOrder + 1
            return sOrder
        end)
        Section.Body = Body
        return Section
    end

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then self:SelectTab(Tab) end
    return Tab
end

-------------------------------------------------
-- ESP PREVIEW PANEL
-------------------------------------------------
function Library:CreateESPPreview(options)
    options = options or {}
    local T = self.Theme
    local Preview = {State = {Box = true, Name = true, Distance = true, Health = true, Highlight = false}}
    local color = T.Accent

    local PW = 208
    local PH = math.min(330, self.Config.Size.Y.Offset)

    -- widen the container to fit the panel
    local mainW = self.Config.Size.X.Offset
    self._totalW = mainW + 12 + PW
    self.Container.Size = UDim2.new(0, self._totalW, 0, self.Config.Size.Y.Offset)
    self._winScale.Scale = self._fitScale()

    local Panel = New("CanvasGroup", {
        Name = "Preview", Position = UDim2.new(0, mainW + 12, 0, 0), Size = UDim2.new(0, PW, 0, PH),
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.03, BorderSizePixel = 0,
        GroupTransparency = self.IsHidden and 1 or 0, Parent = self.Container,
    }, {
        Corner(16), Stroke(T.Stroke, 0.1, 1),
        Gradient(Color3.fromRGB(24, 24, 44), Color3.fromRGB(13, 14, 24), 90),
    })
    table.insert(self._groups, Panel)

    New("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 16, 0, 14), BackgroundTransparency = 1,
        Text = options.Title or "ESP Preview", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = Panel,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -28, 0, 14), Position = UDim2.new(0, 16, 0, 33), BackgroundTransparency = 1,
        Text = options.Subtitle or "Tap an element to toggle it", Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left, Parent = Panel,
    })

    local Stage = New("Frame", {
        Size = UDim2.new(1, -24, 1, -64), Position = UDim2.new(0, 12, 0, 54), BackgroundColor3 = T.Panel,
        BackgroundTransparency = 0.2, BorderSizePixel = 0, ClipsDescendants = true, Parent = Panel,
    }, {Corner(12)})

    local CX = 92
    local Parts = {}
    local dark, skin = Color3.fromRGB(34, 34, 44), Color3.fromRGB(214, 182, 142)
    local function Part(x, y, w, h, c, round)
        local p = New("Frame", {
            Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, w, 0, h), BackgroundColor3 = c,
            BorderSizePixel = 0, Parent = Stage,
        })
        if round then Corner(round).Parent = p end
        local s = Stroke(color, 1, 2)
        s.Parent = p
        table.insert(Parts, {Frame = p, Stroke = s, Base = c})
    end
    Part(CX - 12, 62, 24, 24, skin, 12)
    Part(CX - 22, 88, 44, 50, dark)
    Part(CX - 38, 88, 14, 46, dark)
    Part(CX + 24, 88, 14, 46, dark)
    Part(CX - 22, 140, 21, 54, dark)
    Part(CX + 1, 140, 21, 54, dark)

    local BoxBtn = New("TextButton", {
        Position = UDim2.new(0, CX - 42, 0, 54), Size = UDim2.new(0, 84, 0, 146), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, Parent = Stage,
    })
    local BoxStroke = Stroke(color, 0, 1.5)
    BoxStroke.Parent = BoxBtn
    local NameBtn = New("TextButton", {
        Position = UDim2.new(0, CX - 40, 0, 35), Size = UDim2.new(0, 80, 0, 16), BackgroundTransparency = 1,
        Text = "Dummy", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Text, AutoButtonColor = false,
        Parent = Stage,
    })
    local DistBtn = New("TextButton", {
        Position = UDim2.new(0, CX - 40, 0, 203), Size = UDim2.new(0, 80, 0, 16), BackgroundTransparency = 1,
        Text = "13m", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.Sub, AutoButtonColor = false,
        Parent = Stage,
    })
    local HealthBack = New("TextButton", {
        Position = UDim2.new(0, CX - 50, 0, 54), Size = UDim2.new(0, 4, 0, 146),
        BackgroundColor3 = Color3.fromRGB(10, 10, 16), BorderSizePixel = 0, Text = "", AutoButtonColor = false,
        Parent = Stage,
    }, {Corner(2)})
    local HealthFill = New("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0.75, 0),
        BackgroundColor3 = Color3.fromRGB(80, 230, 130), BorderSizePixel = 0, Parent = HealthBack,
    }, {Corner(2)})

    local function Render()
        local S = Preview.State
        Tween(BoxStroke, {Transparency = S.Box and 0 or 1, Color = color}, 0.2)
        Tween(NameBtn, {TextTransparency = S.Name and 0 or 1}, 0.2)
        Tween(DistBtn, {TextTransparency = S.Distance and 0 or 1}, 0.2)
        Tween(HealthBack, {BackgroundTransparency = S.Health and 0 or 1}, 0.2)
        Tween(HealthFill, {BackgroundTransparency = S.Health and 0 or 1}, 0.2)
        for _, p in ipairs(Parts) do
            Tween(p.Stroke, {Transparency = S.Highlight and 0.1 or 1, Color = color}, 0.2)
            Tween(p.Frame, {BackgroundColor3 = S.Highlight and p.Base:Lerp(color, 0.45) or p.Base}, 0.2)
        end
    end
    Render()

    local bound = {}

    function Preview:Set(element, value)
        if self.State[element] == nil then return end
        self.State[element] = value and true or false
        Render()
    end

    function Preview:SetColor(c)
        color = c
        Render()
    end

    -- Bind a toggle API to a preview element ("Box","Name","Distance","Health","Highlight")
    function Preview:Bind(element, api)
        bound[element] = api
        self:Set(element, api:Get())
        api:OnChanged(function(v) Preview:Set(element, v) end)
    end

    function Preview:BindColor(api)
        self:SetColor(api:Get())
        api:OnChanged(function(c) Preview:SetColor(c) end)
    end

    local function Click(element)
        local api = bound[element]
        if api then
            api:Set(not api:Get())
        else
            Preview:Set(element, not Preview.State[element])
        end
    end
    BoxBtn.MouseButton1Click:Connect(function() Click("Box") end)
    NameBtn.MouseButton1Click:Connect(function() Click("Name") end)
    DistBtn.MouseButton1Click:Connect(function() Click("Distance") end)
    HealthBack.MouseButton1Click:Connect(function() Click("Health") end)
    for _, p in ipairs(Parts) do
        local hit = New("TextButton", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            ZIndex = 0, Parent = p.Frame,
        })
        hit.MouseButton1Click:Connect(function() Click("Highlight") end)
    end

    Preview.Panel = Panel
    return Preview
end

-------------------------------------------------
-- KEY SYSTEM
-------------------------------------------------
function Library:CreateKeySystem(options)
    options = options or {}
    local T = {}
    for k, v in pairs(Theme) do T[k] = v end
    if options.Accent then T.Accent = options.Accent end
    local title = options.Title or "Key System"
    local link = options.Link or "https://example.com"
    local note = options.Note or "Enter your key below"
    local callback = options.Callback or function() end

    local Parent = GuiParent()
    local old = Parent:FindFirstChild("sqservicesKeySystem")
    if old then old:Destroy() end

    local ScreenGui = New("ScreenGui", {
        Name = "sqservicesKeySystem", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000, IgnoreGuiInset = true, Parent = Parent,
    })
    local Overlay = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, Parent = ScreenGui,
    })
    Tween(Overlay, {BackgroundTransparency = 0.45}, 0.4)

    local Box = New("CanvasGroup", {
        Name = "KeyBox", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 360, 0, 214), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        GroupTransparency = 1, Parent = Overlay,
    }, {
        Corner(16), Stroke(T.Stroke, 0.1, 1),
        Gradient(Color3.fromRGB(24, 24, 44), Color3.fromRGB(13, 14, 24), 90),
    })
    local BoxScale = New("UIScale", {Scale = 0.94, Parent = Box})
    Tween(Box, {GroupTransparency = 0}, 0.35)
    Tween(BoxScale, {Scale = 1}, 0.45, Enum.EasingStyle.Back)

    local Badge = New("Frame", {
        Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 18, 0, 16), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Parent = Box,
    }, {Corner(8), Gradient(T.Accent, T.Accent2, 45)})
    New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "K", Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = Color3.new(1, 1, 1), Parent = Badge,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -70, 0, 22), Position = UDim2.new(0, 56, 0, 19), BackgroundTransparency = 1, Text = title,
        Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Box,
    })
    local Note = New("TextLabel", {
        Size = UDim2.new(1, -40, 0, 16), Position = UDim2.new(0, 20, 0, 54), BackgroundTransparency = 1, Text = note,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Box,
    })
    local TextBox = New("TextBox", {
        Name = "KeyInput", Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 80),
        BackgroundColor3 = T.Card, BorderSizePixel = 0, PlaceholderText = "Enter key here...",
        PlaceholderColor3 = T.Sub, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.Text,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
    }, {Corner(10), Pad(14, 14, 0, 0)})
    local boxStroke = Stroke(T.Stroke, 0, 1)
    boxStroke.Parent = TextBox
    TextBox.Focused:Connect(function() Tween(boxStroke, {Color = T.Accent, Transparency = 0.3}, 0.18) end)
    TextBox.FocusLost:Connect(function() Tween(boxStroke, {Color = T.Stroke, Transparency = 0}, 0.18) end)

    local Buttons = New("Frame", {
        Size = UDim2.new(1, -40, 0, 38), Position = UDim2.new(0, 20, 0, 140), BackgroundTransparency = 1, Parent = Box,
    }, {New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })})

    local function makeBtn(text, primary)
        local b = New("TextButton", {
            Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = primary and Color3.new(1, 1, 1) or T.Card,
            BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = primary and Color3.new(1, 1, 1) or T.Text, Text = text, Parent = Buttons,
        }, {Corner(10)})
        if primary then
            Gradient(T.Accent, T.Accent2, 0).Parent = b
        else
            Stroke(T.Stroke, 0, 1).Parent = b
        end
        local s = New("UIScale", {Scale = 1, Parent = b})
        b.MouseEnter:Connect(function()
            if not primary then Tween(b, {BackgroundColor3 = T.CardHover}, 0.15) end
        end)
        b.MouseLeave:Connect(function()
            if not primary then Tween(b, {BackgroundColor3 = T.Card}, 0.15) end
            Tween(s, {Scale = 1}, 0.15)
        end)
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
        for _ = 1, 3 do
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
            Note.TextColor3 = isError and T.Danger or T.Sub
            if isError then task.spawn(shake) end
        end,
    }
end

return Library
