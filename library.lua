local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {
    LogsEnabled = true,
    Flags = {},
    Windows = {},
    Connections = {},
    Theme = {
        Accent = Color3.fromRGB(160, 92, 255),
        AccentDark = Color3.fromRGB(95, 42, 180),
        Background = Color3.fromRGB(6, 8, 13),
        Sidebar = Color3.fromRGB(8, 10, 16),
        Panel = Color3.fromRGB(13, 15, 23),
        PanelLight = Color3.fromRGB(18, 20, 30),
        Stroke = Color3.fromRGB(42, 32, 68),
        StrokeSoft = Color3.fromRGB(28, 30, 42),
        Text = Color3.fromRGB(235, 236, 245),
        Muted = Color3.fromRGB(160, 162, 175),
        Off = Color3.fromRGB(44, 47, 58),
        Green = Color3.fromRGB(48, 224, 115),
    },
}

local function getParent()
    if gethui then
        local ok, parent = pcall(gethui)
        if ok and parent then
            return parent
        end
    end

    if CoreGui then
        return CoreGui
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Library.Connections, connection)
    return connection
end

local function create(className, properties, children)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    for _, child in ipairs(children or {}) do
        child.Parent = object
    end

    return object
end

local function corner(radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    })
end

local function stroke(color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Library.Theme.StrokeSoft,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(left, top, right, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
    })
end

local function listLayout(paddingSize)
    return create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, paddingSize or 8),
    })
end

local function tween(object, properties, duration)
    local ok, animation = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            properties
        )
    end)

    if ok and animation then
        animation:Play()
    else
        for property, value in pairs(properties) do
            object[property] = value
        end
    end
end

local function bindHover(button, enter, leave)
    connect(button.MouseEnter, function()
        tween(button, enter, 0.12)
    end)

    connect(button.MouseLeave, function()
        tween(button, leave, 0.12)
    end)
end

local function textLabel(text, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        TextSize = size or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function normalizeImage(image)
    if type(image) == "number" then
        return "rbxassetid://" .. tostring(image)
    end

    return image
end

local function getSectionIcon(name)
    name = string.lower(tostring(name or ""))

    if string.find(name, "aim") or string.find(name, "combat") then
        return "+"
    elseif string.find(name, "target") then
        return "o"
    elseif string.find(name, "weapon") or string.find(name, "fire") then
        return ">"
    elseif string.find(name, "visual") or string.find(name, "color") or string.find(name, "style") then
        return "*"
    elseif string.find(name, "chams") then
        return "#"
    elseif string.find(name, "sound") then
        return "~"
    elseif string.find(name, "world") then
        return "@"
    elseif string.find(name, "config") or string.find(name, "profile") or string.find(name, "setting") then
        return "="
    end

    return "+"
end

local function formatNumber(value, decimals, suffix)
    decimals = decimals or 0
    local multiplier = 10 ^ decimals
    value = math.floor(value * multiplier + 0.5) / multiplier

    if decimals <= 0 then
        return tostring(math.floor(value + 0.5)) .. (suffix or "")
    end

    return string.format("%." .. tostring(decimals) .. "f", value) .. (suffix or "")
end

local function clampNumber(value, minValue, maxValue)
    if type(value) ~= "number" or value ~= value then
        value = minValue
    end

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function setCallback(callback, ...)
    if callback then
        task.spawn(callback, ...)
    end
end

local function createCrewmateLogo(parent)
    local holder = create("Frame", {
        Name = "CrewmateLogo",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(118, 96),
        Parent = parent,
    })

    local pack = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(98, 40, 204),
        Position = UDim2.fromOffset(18, 28),
        Size = UDim2.fromOffset(26, 54),
        ZIndex = 2,
        Parent = holder,
    }, {corner(13), stroke(Color3.fromRGB(128, 68, 245), 2, 0)})

    local body = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(126, 54, 232),
        Position = UDim2.fromOffset(35, 12),
        Size = UDim2.fromOffset(58, 75),
        ZIndex = 3,
        Parent = holder,
    }, {corner(23), stroke(Color3.fromRGB(176, 99, 255), 3, 0)})

    create("Frame", {
        BackgroundColor3 = Color3.fromRGB(106, 45, 204),
        Position = UDim2.fromOffset(44, 79),
        Size = UDim2.fromOffset(16, 22),
        ZIndex = 3,
        Parent = holder,
    }, {corner(7)})

    create("Frame", {
        BackgroundColor3 = Color3.fromRGB(106, 45, 204),
        Position = UDim2.fromOffset(71, 79),
        Size = UDim2.fromOffset(16, 22),
        ZIndex = 3,
        Parent = holder,
    }, {corner(7)})

    local visor = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(117, 217, 244),
        Position = UDim2.fromOffset(54, 25),
        Size = UDim2.fromOffset(47, 25),
        ZIndex = 4,
        Parent = holder,
    }, {corner(14), stroke(Color3.fromRGB(32, 43, 72), 3, 0)})

    create("Frame", {
        BackgroundColor3 = Color3.fromRGB(230, 255, 255),
        Position = UDim2.fromOffset(15, 5),
        Size = UDim2.fromOffset(19, 6),
        ZIndex = 5,
        Parent = visor,
    }, {corner(4)})

    for _, dot in ipairs({
        {8, 20, 4}, {101, 19, 4}, {97, 57, 3}, {6, 60, 3},
    }) do
        create("Frame", {
            BackgroundColor3 = Library.Theme.Accent,
            BackgroundTransparency = 0.2,
            Position = UDim2.fromOffset(dot[1], dot[2]),
            Size = UDim2.fromOffset(dot[3], dot[3]),
            Parent = holder,
        }, {corner(dot[3])})
    end

    return holder
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition

    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = target.Position
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

local function updateSwitch(track, knob, value)
    local theme = Library.Theme
    local trackColor = value and theme.Accent or theme.Off
    local knobPosition = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)

    tween(track, {BackgroundColor3 = trackColor}, 0.14)
    tween(knob, {Position = knobPosition}, 0.14)
end

local Section = {}
Section.__index = Section

function Section:_createRow(height)
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 36),
        ZIndex = 10,
        Parent = self.Content,
    })

    return row
end

function Section:_refresh()
    if self.Page and self.Page.Refresh then
        self.Page:Refresh()
    end
end

function Section:Toggle(data)
    data = data or {}
    local row = self:_createRow(34)
    local label = textLabel(data.Name or "Toggle", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(1, -64, 1, 0)
    label.Parent = row

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Position = UDim2.new(1, -48, 0.5, -11),
        Size = UDim2.fromOffset(44, 22),
        Parent = row,
    })

    local track = create("Frame", {
        BackgroundColor3 = Library.Theme.Off,
        Size = UDim2.fromScale(1, 1),
        Parent = button,
    }, {corner(12), stroke(Color3.fromRGB(60, 62, 76), 1, 0.35)})

    local knob = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(230, 230, 240),
        Position = UDim2.new(0, 3, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        Parent = track,
    }, {corner(8)})

    local object = {
        Value = data.Default == true,
        Flag = data.Flag,
    }

    function object:Set(value)
        self.Value = value == true
        if self.Flag then
            Library.Flags[self.Flag] = self.Value
        end
        updateSwitch(track, knob, self.Value)
        setCallback(data.Callback, self.Value)
    end

    if object.Flag then
        Library.Flags[object.Flag] = object.Value
    end

    updateSwitch(track, knob, object.Value)
    connect(button.MouseButton1Click, function()
        object:Set(not object.Value)
    end)

    return object
end

function Section:Slider(data)
    data = data or {}
    local minValue = data.Min or 0
    local maxValue = data.Max or 100
    local decimals = data.Decimals or 0
    local row = self:_createRow(42)

    local label = textLabel(data.Name or "Slider", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(0, 135, 1, 0)
    label.Parent = row

    local valueBox = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        Position = UDim2.new(1, -64, 0.5, -15),
        Size = UDim2.fromOffset(62, 30),
        Parent = row,
    }, {corner(7), stroke(Library.Theme.StrokeSoft, 1, 0.2)})

    local valueText = textLabel("", 13, Library.Theme.Text, false)
    valueText.Size = UDim2.fromScale(1, 1)
    valueText.TextXAlignment = Enum.TextXAlignment.Center
    valueText.Parent = valueBox

    local track = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(8, 9, 14),
        Position = UDim2.new(0, 145, 0.5, -2),
        Size = UDim2.new(1, -225, 0, 4),
        Parent = row,
    }, {corner(4)})

    local fill = create("Frame", {
        BackgroundColor3 = Library.Theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = track,
    }, {corner(4)})

    local knob = create("Frame", {
        BackgroundColor3 = Library.Theme.Accent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(13, 13),
        Parent = track,
    }, {corner(7)})

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Position = UDim2.new(0, 145, 0, 0),
        Size = UDim2.new(1, -225, 1, 0),
        Parent = row,
    })

    local object = {
        Value = clampNumber(data.Default or minValue, minValue, maxValue),
        Flag = data.Flag,
    }

    local dragging = false

    local function setFromAlpha(alpha, fire)
        alpha = clampNumber(alpha, 0, 1)
        local value = minValue + (maxValue - minValue) * alpha
        local multiplier = 10 ^ decimals
        value = math.floor(value * multiplier + 0.5) / multiplier
        object.Value = clampNumber(value, minValue, maxValue)

        local percent = 0
        if maxValue ~= minValue then
            percent = (object.Value - minValue) / (maxValue - minValue)
        end

        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.fromScale(percent, 0.5)
        valueText.Text = formatNumber(object.Value, decimals, data.Suffix)

        if object.Flag then
            Library.Flags[object.Flag] = object.Value
        end

        if fire ~= false then
            setCallback(data.Callback, object.Value)
        end
    end

    function object:Set(value)
        local alpha = 0
        if maxValue ~= minValue then
            alpha = (clampNumber(value, minValue, maxValue) - minValue) / (maxValue - minValue)
        end
        setFromAlpha(alpha, true)
    end

    local function updateFromInput(input)
        local absolutePosition = track.AbsolutePosition.X
        local absoluteSize = math.max(track.AbsoluteSize.X, 1)
        setFromAlpha((input.Position.X - absolutePosition) / absoluteSize, true)
    end

    connect(button.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromInput(input)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)

    setFromAlpha(maxValue ~= minValue and ((object.Value - minValue) / (maxValue - minValue)) or 0, false)
    return object
end

function Section:Dropdown(data)
    data = data or {}
    local row = self:_createRow(38)
    local items = data.Items or {}
    local open = false

    local label = textLabel(data.Name or "Dropdown", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(0, 132, 0, 38)
    label.Parent = row

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        Position = UDim2.new(0, 145, 0, 2),
        Size = UDim2.new(1, -147, 0, 34),
        Text = "",
        Parent = row,
    }, {corner(7), stroke(Library.Theme.StrokeSoft, 1, 0.2)})

    local selectedText = textLabel(tostring(data.Default or items[1] or ""), 14, Library.Theme.Text, false)
    selectedText.Position = UDim2.fromOffset(12, 0)
    selectedText.Size = UDim2.new(1, -38, 1, 0)
    selectedText.Parent = button

    local arrow = textLabel("v", 14, Library.Theme.Muted, true)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.Size = UDim2.fromOffset(20, 34)
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Parent = button

    local optionHolder = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        Position = UDim2.new(0, 145, 0, 39),
        Size = UDim2.new(1, -147, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 30,
        Parent = row,
    }, {corner(7), stroke(Library.Theme.StrokeSoft, 1, 0.2), listLayout(0)})

    local object = {
        Value = data.Default or items[1],
        Items = items,
        Flag = data.Flag,
    }

    local function rebuild()
        for _, child in ipairs(optionHolder:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        for index, item in ipairs(object.Items or {}) do
            local option = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Color3.fromRGB(10, 12, 18),
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                Text = tostring(item),
                TextColor3 = Library.Theme.Muted,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 28),
                LayoutOrder = index,
                ZIndex = 31,
                Parent = optionHolder,
            })
            create("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = option})

            bindHover(option, {BackgroundColor3 = Color3.fromRGB(18, 20, 30), TextColor3 = Library.Theme.Text}, {BackgroundColor3 = Color3.fromRGB(10, 12, 18), TextColor3 = Library.Theme.Muted})
            connect(option.MouseButton1Click, function()
                object:Set(item)
                open = false
                optionHolder.Visible = false
                row.Size = UDim2.new(1, 0, 0, 38)
                arrow.Text = "v"
                self:_refresh()
            end)
        end
    end

    function object:Set(value)
        self.Value = value
        selectedText.Text = tostring(value or "")
        if self.Flag then
            Library.Flags[self.Flag] = value
        end
        setCallback(data.Callback, value)
    end

    function object:Refresh(newItems, selected)
        self.Items = newItems or {}
        if selected ~= nil then
            self.Value = selected
            selectedText.Text = tostring(selected)
        end
        rebuild()
    end

    function object:SetOptions(newItems, selected)
        return self:Refresh(newItems, selected)
    end

    if object.Flag then
        Library.Flags[object.Flag] = object.Value
    end

    rebuild()

    connect(button.MouseButton1Click, function()
        open = not open
        local height = math.min(#(object.Items or {}) * 28, 196)
        optionHolder.Visible = open
        optionHolder.Size = UDim2.new(1, -147, 0, height)
        row.Size = UDim2.new(1, 0, 0, open and (44 + height) or 38)
        arrow.Text = open and "^" or "v"
        self:_refresh()
    end)

    return object
end

function Section:Colorpicker(data)
    data = data or {}
    local row = self:_createRow(38)
    local open = false

    local label = textLabel(data.Name or "Color", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(1, -58, 0, 38)
    label.Parent = row

    local swatchButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = data.Default or Library.Theme.Accent,
        Position = UDim2.new(1, -42, 0.5, -13),
        Size = UDim2.fromOffset(38, 26),
        Text = "",
        Parent = row,
    }, {corner(7), stroke(Library.Theme.StrokeSoft, 1, 0.1)})

    local picker = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 98),
        Visible = false,
        Parent = row,
    })

    local object = {
        Value = data.Default or Library.Theme.Accent,
        Flag = data.Flag,
    }

    local rgb = {
        R = math.floor(object.Value.R * 255 + 0.5),
        G = math.floor(object.Value.G * 255 + 0.5),
        B = math.floor(object.Value.B * 255 + 0.5),
    }

    local function applyColor(fire)
        object.Value = Color3.fromRGB(rgb.R, rgb.G, rgb.B)
        swatchButton.BackgroundColor3 = object.Value
        if object.Flag then
            Library.Flags[object.Flag] = object.Value
        end
        if fire ~= false then
            setCallback(data.Callback, object.Value, data.Alpha or 1)
        end
    end

    local function miniSlider(name, index)
        local sliderRow = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, (index - 1) * 31),
            Size = UDim2.new(1, 0, 0, 30),
            Parent = picker,
        })

        local sliderLabel = textLabel(name, 12, Library.Theme.Muted, true)
        sliderLabel.Size = UDim2.fromOffset(18, 30)
        sliderLabel.Parent = sliderRow

        local track = create("Frame", {
            BackgroundColor3 = Color3.fromRGB(8, 9, 14),
            Position = UDim2.fromOffset(28, 13),
            Size = UDim2.new(1, -80, 0, 4),
            Parent = sliderRow,
        }, {corner(4)})

        local fill = create("Frame", {
            BackgroundColor3 = Library.Theme.Accent,
            Size = UDim2.fromScale(rgb[name] / 255, 1),
            Parent = track,
        }, {corner(4)})

        local valueText = textLabel(tostring(rgb[name]), 12, Library.Theme.Text, false)
        valueText.Position = UDim2.new(1, -42, 0, 0)
        valueText.Size = UDim2.fromOffset(40, 30)
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.Parent = sliderRow

        local hitbox = create("TextButton", {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Text = "",
            Position = UDim2.fromOffset(28, 0),
            Size = UDim2.new(1, -80, 1, 0),
            Parent = sliderRow,
        })

        local dragging = false
        local function update(input)
            local alpha = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
            alpha = clampNumber(alpha, 0, 1)
            rgb[name] = math.floor(alpha * 255 + 0.5)
            fill.Size = UDim2.fromScale(alpha, 1)
            valueText.Text = tostring(rgb[name])
            applyColor(true)
        end

        connect(hitbox.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input)
            end
        end)

        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        connect(UserInputService.InputChanged, function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
    end

    miniSlider("R", 1)
    miniSlider("G", 2)
    miniSlider("B", 3)

    function object:Set(value)
        self.Value = value
        rgb.R = math.floor(value.R * 255 + 0.5)
        rgb.G = math.floor(value.G * 255 + 0.5)
        rgb.B = math.floor(value.B * 255 + 0.5)
        applyColor(false)
    end

    if object.Flag then
        Library.Flags[object.Flag] = object.Value
    end

    connect(swatchButton.MouseButton1Click, function()
        open = not open
        picker.Visible = open
        row.Size = UDim2.new(1, 0, 0, open and 142 or 38)
        self:_refresh()
    end)

    applyColor(false)
    return object
end

Section.ColorPicker = Section.Colorpicker

function Section:Keybind(data)
    data = data or {}
    local row = self:_createRow(38)
    local waiting = false
    local state = false
    local currentKey = data.Default

    local label = textLabel(data.Name or "Keybind", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(1, -118, 1, 0)
    label.Parent = row

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        Position = UDim2.new(1, -108, 0.5, -15),
        Size = UDim2.fromOffset(104, 30),
        Font = Enum.Font.Gotham,
        Text = currentKey and currentKey.Name or "None",
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        Parent = row,
    }, {corner(7), stroke(Library.Theme.StrokeSoft, 1, 0.2)})

    connect(button.MouseButton1Click, function()
        waiting = true
        button.Text = "..."
    end)

    connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if waiting then
            currentKey = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or currentKey
            waiting = false
            button.Text = currentKey and currentKey.Name or "None"
            return
        end

        if currentKey and input.KeyCode == currentKey then
            if data.Mode == "Toggle" then
                state = not state
                setCallback(data.Callback, state)
            else
                setCallback(data.Callback, true)
            end
        end
    end)

    return {
        Key = currentKey,
        Set = function(self, key)
            currentKey = key
            self.Key = key
            button.Text = key and key.Name or "None"
        end,
    }
end

local Page = {}
Page.__index = Page

function Page:Refresh()
    local leftHeight = self.LeftLayout.AbsoluteContentSize.Y
    local rightHeight = self.RightLayout.AbsoluteContentSize.Y
    local height = math.max(leftHeight, rightHeight, 1)

    self.LeftColumn.Size = UDim2.new(0.5, -7, 0, leftHeight)
    self.RightColumn.Size = UDim2.new(0.5, -7, 0, rightHeight)
    self.Columns.Size = UDim2.new(1, -8, 0, height)
    self.Scroll.CanvasSize = UDim2.fromOffset(0, height + 22)
end

function Page:Section(data)
    data = data or {}
    local parent = data.Side == 2 and self.RightColumn or self.LeftColumn

    local card = create("Frame", {
        BackgroundColor3 = Library.Theme.Panel,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    }, {
        corner(9),
        stroke(Library.Theme.StrokeSoft, 1, 0.3),
        padding(14, 13, 14, 14),
        listLayout(10),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = card,
    })

    local icon = textLabel(getSectionIcon(data.Name), 18, Library.Theme.Accent, true)
    icon.Size = UDim2.fromOffset(24, 24)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = header

    local title = textLabel(data.Name or "Section", 16, Library.Theme.Accent, true)
    title.Position = UDim2.fromOffset(32, 0)
    title.Size = UDim2.new(1, -32, 1, 0)
    title.Parent = header

    local content = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    }, {listLayout(7)})

    local section = setmetatable({
        Frame = card,
        Content = content,
        Page = self,
    }, Section)

    connect(card:GetPropertyChangedSignal("AbsoluteSize"), function()
        section:_refresh()
    end)
    connect(content.ChildAdded, function()
        task.defer(function()
            section:_refresh()
        end)
    end)

    task.defer(function()
        section:_refresh()
    end)

    return section
end

local Window = {}
Window.__index = Window

function Window:SetOpen(open)
    self.IsOpen = open == true
    if self.Gui then
        self.Gui.Enabled = self.IsOpen
    end
end

function Window:_selectPage(page)
    self.ActivePage = page

    for _, item in ipairs(self.Pages) do
        local active = item == page
        item.Scroll.Visible = active
        item.SideButton.BackgroundTransparency = active and 0 or 1
        item.SideButton.TextColor3 = active and Library.Theme.Text or Library.Theme.Muted
        item.TopButton.TextColor3 = active and Library.Theme.Accent or Library.Theme.Muted
        item.TopAccent.Visible = active

        if item.SideIcon then
            item.SideIcon.ImageColor3 = active and Library.Theme.Accent or Library.Theme.Muted
        end
    end

    page:Refresh()
end

function Window:Page(data)
    data = data or {}
    local index = #self.Pages + 1

    local sideButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(21, 18, 34),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = data.Name or ("Page " .. tostring(index)),
        TextColor3 = Library.Theme.Muted,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = self.SideList,
    }, {corner(8), padding(48, 0, 8, 0), stroke(Library.Theme.Stroke, 1, 0.45)})

    local sideIcon
    if data.Icon then
        sideIcon = create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = normalizeImage(data.Icon),
            ImageColor3 = Library.Theme.Muted,
            Position = UDim2.fromOffset(15, 12),
            Size = UDim2.fromOffset(20, 20),
            Parent = sideButton,
        })
    else
        local fallback = textLabel(string.sub(data.Name or "P", 1, 1), 16, Library.Theme.Muted, true)
        fallback.Position = UDim2.fromOffset(15, 0)
        fallback.Size = UDim2.fromOffset(20, 44)
        fallback.TextXAlignment = Enum.TextXAlignment.Center
        fallback.Parent = sideButton
    end

    local topButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = data.Name or ("Page " .. tostring(index)),
        TextColor3 = Library.Theme.Muted,
        TextSize = 14,
        Size = UDim2.fromOffset(104, 48),
        Parent = self.TopTabs,
    })

    local topAccent = create("Frame", {
        BackgroundColor3 = Library.Theme.Accent,
        Position = UDim2.new(0, 8, 1, -3),
        Size = UDim2.new(1, -16, 0, 3),
        Visible = false,
        Parent = topButton,
    }, {corner(3)})

    local scroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Theme.Accent,
        Position = UDim2.fromOffset(0, 74),
        Size = UDim2.new(1, 0, 1, -74),
        CanvasSize = UDim2.fromOffset(0, 0),
        Visible = false,
        Parent = self.Content,
    })

    local columns = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -8, 0, 0),
        Parent = scroll,
    })

    local leftColumn = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0.5, -7, 0, 0),
        Parent = columns,
    }, {listLayout(10)})

    local rightColumn = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 7, 0, 0),
        Size = UDim2.new(0.5, -7, 0, 0),
        Parent = columns,
    }, {listLayout(10)})

    local page = setmetatable({
        Name = data.Name,
        Scroll = scroll,
        Columns = columns,
        LeftColumn = leftColumn,
        RightColumn = rightColumn,
        LeftLayout = leftColumn:FindFirstChildOfClass("UIListLayout"),
        RightLayout = rightColumn:FindFirstChildOfClass("UIListLayout"),
        SideButton = sideButton,
        SideIcon = sideIcon,
        TopButton = topButton,
        TopAccent = topAccent,
        Window = self,
    }, Page)

    connect(sideButton.MouseButton1Click, function()
        self:_selectPage(page)
    end)

    connect(topButton.MouseButton1Click, function()
        self:_selectPage(page)
    end)

    connect(page.LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        page:Refresh()
    end)

    connect(page.RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        page:Refresh()
    end)

    table.insert(self.Pages, page)

    if not self.ActivePage then
        self:_selectPage(page)
    end

    return page
end

function Library:Window(data)
    data = data or {}

    local gui = create("ScreenGui", {
        Name = "AmongusHookLibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483647,
        Enabled = true,
        Parent = getParent(),
    })

    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end

    self.Holder = gui

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1366, 768)
    local width = math.min(980, math.max(780, viewport.X - 72))
    local height = math.min(640, math.max(540, viewport.Y - 72))

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Background,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        Parent = gui,
    }, {corner(14), stroke(self.Theme.Stroke, 1, 0)})

    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 11, 18)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 6, 10)),
        }),
        Rotation = 35,
        Parent = main,
    })

    local sidebar = create("Frame", {
        BackgroundColor3 = self.Theme.Sidebar,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(0, 188, 1, 0),
        Parent = main,
    }, {corner(14)})

    create("Frame", {
        BackgroundColor3 = self.Theme.StrokeSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = sidebar,
    })

    local logoArea = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 154),
        Parent = sidebar,
    })

    local logo = createCrewmateLogo(logoArea)
    logo.AnchorPoint = Vector2.new(0.5, 0)
    logo.Position = UDim2.new(0.5, 0, 0, 16)

    local name = textLabel(data.Name or "Amongus.hook", 20, self.Theme.Text, true)
    name.TextXAlignment = Enum.TextXAlignment.Center
    name.Position = UDim2.fromOffset(0, 104)
    name.Size = UDim2.new(1, 0, 0, 26)
    name.Parent = logoArea

    local subName = textLabel(data.SubName or "CS2 CHEAT", 11, self.Theme.Accent, true)
    subName.TextXAlignment = Enum.TextXAlignment.Center
    subName.Position = UDim2.fromOffset(0, 130)
    subName.Size = UDim2.new(1, 0, 0, 18)
    subName.Parent = logoArea

    local sideList = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(24, 166),
        Size = UDim2.new(1, -48, 1, -260),
        Parent = sidebar,
    }, {listLayout(9)})

    local status = create("Frame", {
        BackgroundColor3 = self.Theme.PanelLight,
        BackgroundTransparency = 0.08,
        Position = UDim2.new(0, 24, 1, -86),
        Size = UDim2.new(1, -48, 0, 66),
        Parent = sidebar,
    }, {corner(8), stroke(self.Theme.StrokeSoft, 1, 0.25), padding(12, 9, 12, 9)})

    local statusTitle = textLabel(data.Name or "Amongus.hook", 13, self.Theme.Accent, true)
    statusTitle.Size = UDim2.new(1, -18, 0, 18)
    statusTitle.Parent = status

    local statusDot = create("Frame", {
        BackgroundColor3 = self.Theme.Green,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 6),
        Size = UDim2.fromOffset(9, 9),
        Parent = status,
    }, {corner(9)})

    local version = textLabel("Version: 1.0.0", 12, self.Theme.Muted, false)
    version.Position = UDim2.fromOffset(0, 22)
    version.Size = UDim2.new(1, 0, 0, 16)
    version.Parent = status

    local injected = textLabel("Status: Injected", 12, self.Theme.Green, false)
    injected.Position = UDim2.fromOffset(0, 42)
    injected.Size = UDim2.new(1, 0, 0, 16)
    injected.Parent = status

    local content = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(202, 16),
        Size = UDim2.new(1, -218, 1, -32),
        Parent = main,
    })

    local top = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = content,
    })

    local topTabs = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ClipsDescendants = true,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        Size = UDim2.new(1, -160, 1, 0),
        Parent = top,
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
        }),
    })

    local topTabsLayout = topTabs:FindFirstChildOfClass("UIListLayout")
    connect(topTabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        topTabs.CanvasSize = UDim2.fromOffset(topTabsLayout.AbsoluteContentSize.X + 8, 0)
    end)

    local product = textLabel("CS2  -  Prime", 14, self.Theme.Text, true)
    product.AnchorPoint = Vector2.new(1, 0)
    product.Position = UDim2.new(1, -36, 0, 15)
    product.Size = UDim2.fromOffset(120, 28)
    product.TextXAlignment = Enum.TextXAlignment.Right
    product.Parent = top

    create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -128, 0, 24),
        Size = UDim2.fromOffset(9, 9),
        Parent = top,
    }, {corner(9)})

    local close = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = "X",
        TextColor3 = self.Theme.Muted,
        TextSize = 18,
        Position = UDim2.new(1, -24, 0, 7),
        Size = UDim2.fromOffset(24, 24),
        Parent = top,
    })

    local minimize = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = "-",
        TextColor3 = self.Theme.Muted,
        TextSize = 20,
        Position = UDim2.new(1, -58, 0, 6),
        Size = UDim2.fromOffset(24, 24),
        Parent = top,
    })

    create("Frame", {
        BackgroundColor3 = self.Theme.StrokeSoft,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 62),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = content,
    })

    local window = setmetatable({
        Gui = gui,
        Main = main,
        SideList = sideList,
        TopTabs = topTabs,
        Content = content,
        Pages = {},
        ActivePage = nil,
        IsOpen = true,
    }, Window)

    table.insert(self.Windows, window)

    connect(close.MouseButton1Click, function()
        window:SetOpen(false)
    end)

    connect(minimize.MouseButton1Click, function()
        window:SetOpen(false)
    end)

    makeDraggable(top, main)

    return window
end

function Library:Log(text, duration, color)
    if self.LogsEnabled == false then
        return
    end

    local parent = self.Holder or getParent()
    local toast = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = self.Theme.PanelLight,
        BackgroundTransparency = 0.06,
        Position = UDim2.new(1, -24, 0, 24),
        Size = UDim2.fromOffset(290, 46),
        Parent = parent,
    }, {corner(8), stroke(self.Theme.Stroke, 1, 0.15), padding(12, 0, 12, 0)})

    local label = textLabel(tostring(text), 13, color or self.Theme.Text, false)
    label.Size = UDim2.fromScale(1, 1)
    label.Parent = toast

    task.delay(duration or 3, function()
        if toast and toast.Parent then
            tween(toast, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.22)
            if toast and toast.Parent then
                toast:Destroy()
            end
        end
    end)
end

function Library:Notification(data)
    data = data or {}
    self:Log(data.Description or data.Title or "Notification", data.Duration or 3, self.Theme.Text)
end

function Library:CreateSettingsPage(window)
    if not window or window.__SettingsPageCreated then
        return
    end

    window.__SettingsPageCreated = true
    local page = window:Page({Name = "Settings", Icon = "rbxassetid://6031280882"})
    local section = page:Section({Name = "Menu", Side = 1})
    section:Toggle({
        Name = "Logs",
        Default = self.LogsEnabled,
        Callback = function(value)
            self.LogsEnabled = value
        end,
    })
end

function Library:Unload()
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(self.Connections)

    for _, window in ipairs(self.Windows) do
        if window.Gui then
            window.Gui:Destroy()
        end
    end

    table.clear(self.Windows)
    self.Holder = nil
end

return Library
