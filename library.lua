local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local UI_FONT = Enum.Font.Rajdhani
local UI_FONT_BOLD = Enum.Font.Rajdhani
local UI_FONT_MONO = Enum.Font.Code

local function fontWeight(weight)
    if weight == "mono" then
        return UI_FONT_MONO
    end
    return UI_FONT
end

local Library = {
    LogsEnabled = true,
    LogsVisible = true,
    CurrentScale = 1,
    ConfigFolder = "AmongusHook/configs",
    WatermarkEnabled = true,
    Flags = {},
    Elements = {},
    Windows = {},
    Connections = {},
    ActiveLogs = {},
    LogCounter = 0,
    LoggerGui = nil,
    LoggerPanel = nil,
    LoggerList = nil,
    LoggerScreen = nil,
    AnimationsEnabled = true,
    InputLockCount = 0,
    PreviousMouseBehavior = nil,
    PreviousMouseIconEnabled = nil,
    MovementState = nil,
    Theme = {
        Accent = Color3.fromRGB(166, 92, 255),
        AccentDark = Color3.fromRGB(105, 47, 206),
        Background = Color3.fromRGB(5, 7, 11),
        Sidebar = Color3.fromRGB(7, 8, 13),
        Panel = Color3.fromRGB(12, 14, 21),
        PanelLight = Color3.fromRGB(17, 19, 28),
        Stroke = Color3.fromRGB(55, 36, 88),
        StrokeSoft = Color3.fromRGB(31, 34, 47),
        Text = Color3.fromRGB(240, 240, 248),
        Muted = Color3.fromRGB(164, 166, 178),
        Off = Color3.fromRGB(34, 37, 47),
        Glow = Color3.fromRGB(142, 75, 255),
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

local function setPlayerMovementLocked(locked)
    local character = LocalPlayer and LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if locked then
        if Library.InputLockCount == 0 then
            Library.PreviousMouseBehavior = UserInputService.MouseBehavior
            Library.PreviousMouseIconEnabled = UserInputService.MouseIconEnabled
        end

        Library.InputLockCount = Library.InputLockCount + 1
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        ContextActionService:BindAction(
            "UiLib_BlockMovement",
            function() return Enum.ContextActionResult.Sink end,
            false,
            Enum.PlayerActions.CharacterForward,
            Enum.PlayerActions.CharacterBackward,
            Enum.PlayerActions.CharacterLeft,
            Enum.PlayerActions.CharacterRight,
            Enum.PlayerActions.CharacterJump
        )

        if humanoid and not Library.MovementState then
            Library.MovementState = {
                WalkSpeed = humanoid.WalkSpeed,
                JumpPower = humanoid.JumpPower,
                JumpHeight = humanoid.JumpHeight,
                AutoRotate = humanoid.AutoRotate,
            }
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.JumpHeight = 0
            humanoid.AutoRotate = false
        end
    else
        Library.InputLockCount = math.max((Library.InputLockCount or 1) - 1, 0)
        if Library.InputLockCount == 0 then
            ContextActionService:UnbindAction("UiLib_BlockMovement")
            if Library.PreviousMouseBehavior then
                UserInputService.MouseBehavior = Library.PreviousMouseBehavior
            end
            if Library.PreviousMouseIconEnabled ~= nil then
                UserInputService.MouseIconEnabled = Library.PreviousMouseIconEnabled
            end

            if humanoid and Library.MovementState then
                humanoid.WalkSpeed = Library.MovementState.WalkSpeed or humanoid.WalkSpeed
                humanoid.JumpPower = Library.MovementState.JumpPower or humanoid.JumpPower
                humanoid.JumpHeight = Library.MovementState.JumpHeight or humanoid.JumpHeight
                humanoid.AutoRotate = Library.MovementState.AutoRotate ~= false
            end
            Library.MovementState = nil
        end
    end
end

local function addSoftGlow(parent, radius, color, transparency)
    local glow = create("Frame", {
        Name = "SoftGlow",
        BackgroundColor3 = color or Library.Theme.Glow,
        BackgroundTransparency = transparency or 0.84,
        Position = UDim2.fromOffset(-(radius or 12), -(radius or 12)),
        Size = UDim2.new(1, (radius or 12) * 2, 1, (radius or 12) * 2),
        ZIndex = 0,
        Parent = parent,
    }, {corner((radius or 12) + 14)})

    local gradient = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color or Library.Theme.Glow),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 28)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent = glow,
    })

    return glow, gradient
end

local function textLabel(text, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Font = fontWeight(bold and "bold" or "regular"),
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        TextSize = size or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function applyUiFont(object, weight)
    if object then
        object.Font = fontWeight(weight)
    end
    return object
end

local function normalizeImage(image)
    if type(image) == "number" then
        return "rbxassetid://" .. tostring(image)
    end

    if type(image) == "string" and image:match("^%d+$") then
        return "rbxassetid://" .. image
    end

    return image
end

local function normalizeScale(value)
    if type(value) == "string" then
        value = tonumber(value:match("[%d%.]+"))
    end

    value = tonumber(value) or 1
    if value < 0.5 then
        value = 0.5
    elseif value > 1.5 then
        value = 1.5
    end

    local options = {0.5, 0.75, 1, 1.25, 1.5}
    local nearest = options[1]
    local nearestDelta = math.abs(value - nearest)

    for _, option in ipairs(options) do
        local delta = math.abs(value - option)
        if delta < nearestDelta then
            nearest = option
            nearestDelta = delta
        end
    end

    return nearest
end

local function scaleLabel(value)
    value = normalizeScale(value)
    if value == math.floor(value) then
        return tostring(math.floor(value)) .. "x"
    end
    return tostring(value) .. "x"
end

local function getSectionIcon(name)
    name = string.lower(tostring(name or ""))

    if string.find(name, "target") then
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

local function getPageIcon(name)
    name = string.lower(tostring(name or ""))

    if string.find(name, "visual") then
        return "O"
    elseif string.find(name, "player") then
        return "n"
    elseif string.find(name, "world") then
        return "@"
    elseif string.find(name, "misc") or string.find(name, "tool") then
        return "#"
    elseif string.find(name, "skin") or string.find(name, "inventory") then
        return "/"
    elseif string.find(name, "config") or string.find(name, "profile") then
        return "="
    elseif string.find(name, "setting") then
        return "*"
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

local function registerElement(flag, object)
    if flag then
        Library.Elements[flag] = object
    end
end

local function setFlag(flag, value)
    if flag then
        Library.Flags[flag] = value
    end
end

local function clearTable(list)
    if type(table.clear) == "function" then
        table.clear(list)
        return
    end

    for key in pairs(list) do
        list[key] = nil
    end
end

local function copyArray(value)
    local result = {}
    if type(value) == "table" then
        for _, item in ipairs(value) do
            table.insert(result, item)
        end
    elseif value ~= nil then
        table.insert(result, value)
    end
    return result
end

local function containsValue(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function removeValue(list, value)
    for index = #list, 1, -1 do
        if list[index] == value then
            table.remove(list, index)
        end
    end
end

local function joinValues(list)
    local parts = {}
    for _, item in ipairs(list or {}) do
        table.insert(parts, tostring(item))
    end

    if #parts == 0 then
        return "None"
    end

    return table.concat(parts, ", ")
end

local function enumFromName(enumType, name)
    if enumType and name and Enum[enumType] and Enum[enumType][name] then
        return Enum[enumType][name]
    end
    return nil
end

local function encodeValue(value)
    local valueType = typeof(value)

    if valueType == "Color3" then
        return {
            __type = "Color3",
            R = math.floor(value.R * 255 + 0.5),
            G = math.floor(value.G * 255 + 0.5),
            B = math.floor(value.B * 255 + 0.5),
        }
    end

    if valueType == "EnumItem" then
        return {
            __type = "EnumItem",
            EnumType = value.EnumType.Name,
            Name = value.Name,
        }
    end

    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do
            result[key] = encodeValue(item)
        end
        return result
    end

    return value
end

local function decodeValue(value)
    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Color3" then
        return Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255)
    end

    if value.__type == "EnumItem" then
        return enumFromName(value.EnumType, value.Name)
    end

    local result = {}
    for key, item in pairs(value) do
        result[key] = decodeValue(item)
    end
    return result
end

local function canUseFiles()
    return type(writefile) == "function" and type(readfile) == "function"
end

local function normalizeConfigName(name)
    name = tostring(name or "default")
    name = name:gsub("[^%w_%-%s]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        name = "default"
    end
    return name
end

local function configPath(name)
    return Library.ConfigFolder .. "/" .. normalizeConfigName(name) .. ".json"
end

local function ensureConfigFolder()
    if type(isfolder) == "function" and type(makefolder) == "function" then
        if not isfolder("AmongusHook") then
            pcall(makefolder, "AmongusHook")
        end
        if not isfolder(Library.ConfigFolder) then
            pcall(makefolder, Library.ConfigFolder)
        end
    end
end

local function getConfigNames()
    local names = {"default"}

    if type(listfiles) == "function" then
        ensureConfigFolder()
        local ok, files = pcall(listfiles, Library.ConfigFolder)
        if ok and type(files) == "table" then
            names = {}
            for _, file in ipairs(files) do
                local name = tostring(file):match("([^/\\]+)%.json$")
                if name then
                    table.insert(names, name)
                end
            end
            if #names == 0 then
                table.insert(names, "default")
            end
        end
    end

    table.sort(names)
    return names
end

local function setElementValue(element, value)
    if not element then
        return
    end

    if element.Type == "Colorpicker" then
        if type(value) == "table" and value.Color ~= nil then
            element:Set(value.Color, value.Alpha)
        else
            element:Set(value)
        end
        return
    end

    if element.Type == "Keybind" then
        if type(value) == "table" and value.Key ~= nil then
            element:Set(value)
        else
            element:Set(value)
        end
        return
    end

    if element.Set then
        element:Set(value)
    end
end

local function collectConfig()
    local config = {}
    for flag, element in pairs(Library.Elements) do
        if element.Type ~= "Button" and not tostring(flag):match("^Library_") then
            config[flag] = encodeValue(Library.Flags[flag])
        end
    end
    return config
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

function Library:SetWatermarkVisible(visible)
    self.WatermarkEnabled = visible == true

    for _, window in ipairs(self.Windows) do
        if window.Watermark then
            window.Watermark.Visible = self.WatermarkEnabled
        end
    end
end

function Library:SetLogsVisible(visible)
    self.LogsVisible = visible == true

    if self.LoggerPanel then
        self.LoggerPanel.Visible = self.LogsVisible and self.LogsEnabled ~= false
    end
end

function Library:SetScale(scale)
    self.CurrentScale = normalizeScale(scale)

    for _, window in ipairs(self.Windows) do
        if window.Scale then
            window.Scale.Scale = self.CurrentScale
        end

        if window.WatermarkScale then
            window.WatermarkScale.Scale = self.CurrentScale
        end

        if window.ActivePage then
            window.ActivePage:Refresh()
        end
    end

    if self.LoggerPanel then
        local loggerScale = self.LoggerPanel:FindFirstChildOfClass("UIScale")
        if not loggerScale then
            loggerScale = create("UIScale", {Parent = self.LoggerPanel})
        end
        loggerScale.Scale = self.CurrentScale
    end

    return self.CurrentScale
end

function Library:RefreshConfigList()
    return getConfigNames()
end

function Library:SaveConfig(name)
    if not canUseFiles() then
        return false, "file API unavailable"
    end

    ensureConfigFolder()

    local payload = {
        Version = 1,
        SavedAt = os.time(),
        Flags = collectConfig(),
    }

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(payload)
    end)

    if not ok then
        return false, tostring(encoded)
    end

    local writeOk, writeErr = pcall(writefile, configPath(name), encoded)
    if not writeOk then
        return false, tostring(writeErr)
    end

    return true, normalizeConfigName(name)
end

function Library:LoadConfig(name)
    if not canUseFiles() then
        return false, "file API unavailable"
    end

    local path = configPath(name)
    if type(isfile) == "function" and not isfile(path) then
        return false, "config not found"
    end

    local readOk, contents = pcall(readfile, path)
    if not readOk then
        return false, tostring(contents)
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(contents)
    end)

    if not decodeOk or type(decoded) ~= "table" then
        return false, "invalid config"
    end

    local flags = decoded.Flags or decoded
    if type(flags) ~= "table" then
        return false, "invalid config flags"
    end

    for flag, value in pairs(flags) do
        local element = self.Elements[flag]
        if element then
            setElementValue(element, decodeValue(value))
        end
    end

    return true, normalizeConfigName(name)
end

function Library:DeleteConfig(name)
    if type(delfile) ~= "function" then
        return false, "delete API unavailable"
    end

    local path = configPath(name)
    if type(isfile) == "function" and not isfile(path) then
        return false, "config not found"
    end

    local ok, err = pcall(delfile, path)
    if not ok then
        return false, tostring(err)
    end

    return true, normalizeConfigName(name)
end

local function makeDraggable(handle, target, onRelease)
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            if onRelease then
                onRelease(target)
            end
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

local function updateSwitch(track, knob, glow, value)
    local theme = Library.Theme
    local trackColor = value and theme.Accent or theme.Off
    local knobPosition = value and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    local trackStroke = track and track:FindFirstChildOfClass("UIStroke")

    if glow then
        glow.Visible = true
        tween(glow, {BackgroundTransparency = value and 0.72 or 1}, 0.22)
        task.delay(0.24, function()
            if glow and glow.Parent and not value then
                glow.Visible = false
            end
        end)
    end

    if trackStroke then
        tween(trackStroke, {Color = value and theme.Accent or Color3.fromRGB(45, 48, 60), Transparency = value and 0.05 or 0.35}, 0.18)
    end

    tween(track, {BackgroundColor3 = trackColor}, 0.18)
    tween(knob, {
        Position = knobPosition,
        BackgroundColor3 = value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 150),
        Size = value and UDim2.fromOffset(20, 20) or UDim2.fromOffset(18, 18),
    }, 0.18)
end

local function applySmartSnap(frame)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1366, 768)
    local centerX = viewport.X * 0.5
    local frameCenter = frame.AbsolutePosition.X + frame.AbsoluteSize.X * 0.5

    if math.abs(frameCenter - centerX) <= 28 then
        frame.AnchorPoint = Vector2.new(0.5, frame.AnchorPoint.Y)
        frame.Position = UDim2.new(0.5, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
    end
end

local function updateLoggerStack()
    for index, toast in ipairs(Library.ActiveLogs) do
        if toast and toast.Parent then
            tween(toast, {Position = UDim2.new(0, 0, 0, (index - 1) * 52)}, 0.16)
        end
    end
end

local function removeLogToast(toast)
    for index, item in ipairs(Library.ActiveLogs) do
        if item == toast then
            table.remove(Library.ActiveLogs, index)
            break
        end
    end

    updateLoggerStack()
end

local function ensureLogger()
    local parent = Library.Holder

    if not parent then
        if not Library.LoggerScreen or not Library.LoggerScreen.Parent then
            Library.LoggerScreen = create("ScreenGui", {
                Name = "UiLibLogger",
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                DisplayOrder = 2147483647,
                Parent = getParent(),
            })
        end

        parent = Library.LoggerScreen
    end

    if Library.LoggerGui == parent and Library.LoggerPanel and Library.LoggerPanel.Parent == parent and Library.LoggerList then
        return Library.LoggerPanel, Library.LoggerList
    end

    if Library.LoggerPanel then
        pcall(function()
            Library.LoggerPanel:Destroy()
        end)
    end

    clearTable(Library.ActiveLogs)

    Library.LoggerGui = parent

    local panel = create("Frame", {
        Name = "LogPanel",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 0, 24),
        Size = UDim2.fromOffset(360, 320),
        Visible = Library.LogsVisible,
        Parent = parent,
    })

    create("UIScale", {
        Scale = normalizeScale(Library.CurrentScale),
        Parent = panel,
    })

    local handle = create("Frame", {
        BackgroundColor3 = Library.Theme.PanelLight,
        BackgroundTransparency = 0.04,
        Size = UDim2.fromOffset(190, 24),
        Parent = panel,
    }, {corner(8), stroke(Library.Theme.Stroke, 1, 0.2), padding(10, 0, 10, 0)})

    local handleText = textLabel("Event log", 12, Library.Theme.Muted, true)
    handleText.Size = UDim2.fromScale(1, 1)
    handleText.TextXAlignment = Enum.TextXAlignment.Center
    handleText.Parent = handle

    local list = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 1, -34),
        Parent = panel,
    })

    makeDraggable(handle, panel, applySmartSnap)

    Library.LoggerPanel = panel
    Library.LoggerList = list
    return panel, list
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
    local row = self:_createRow(40)
    local hasChildren = false
    local expanded = false

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = row,
    })

    local labelButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = fontWeight(),
        Text = data.Name or "Toggle",
        TextColor3 = Library.Theme.Muted,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -92, 1, 0),
        Parent = header,
    })

    local expander = textLabel(">", 13, Library.Theme.Muted, true)
    expander.Position = UDim2.new(1, -88, 0, 0)
    expander.Size = UDim2.fromOffset(22, 40)
    expander.TextXAlignment = Enum.TextXAlignment.Center
    expander.Visible = false
    expander.Parent = header

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Position = UDim2.new(1, -48, 0.5, -12),
        Size = UDim2.fromOffset(44, 24),
        Parent = header,
    })

    local track = create("Frame", {
        BackgroundColor3 = Library.Theme.Off,
        Size = UDim2.fromScale(1, 1),
        Parent = button,
    }, {corner(12), stroke(Color3.fromRGB(45, 48, 60), 1, 0.35)})

    local switchGlow = create("Frame", {
        BackgroundColor3 = Library.Theme.Accent,
        BackgroundTransparency = 0.78,
        Position = UDim2.fromOffset(-4, -4),
        Size = UDim2.new(1, 8, 1, 8),
        Visible = false,
        ZIndex = 0,
        Parent = button,
    }, {corner(15)})

    local knob = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(230, 230, 240),
        Position = UDim2.new(0, 3, 0.5, -9),
        Size = UDim2.fromOffset(18, 18),
        Parent = track,
    }, {corner(8)})

    local childHolder = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 11, 17),
        BackgroundTransparency = 0.18,
        Position = UDim2.fromOffset(0, 46),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        Parent = row,
    }, {corner(8), stroke(Library.Theme.StrokeSoft, 1, 0.45), padding(10, 8, 10, 9), listLayout(7)})

    local childLayout = childHolder:FindFirstChildOfClass("UIListLayout")

    local object = {
        Type = "Toggle",
        Value = data.Default == true,
        Flag = data.Flag,
        Content = childHolder,
        Page = self.Page,
        Frame = row,
        Children = {},
        _createRow = Section._createRow,
    }

    local function childHeight()
        return childLayout.AbsoluteContentSize.Y + 17
    end

    function object:_refresh()
        if hasChildren then
            childHolder.Size = UDim2.new(1, 0, 0, expanded and childHeight() or 0)
            row.Size = UDim2.new(1, 0, 0, expanded and (50 + childHeight()) or 40)
        else
            row.Size = UDim2.new(1, 0, 0, 40)
        end

        if self.Page and self.Page.Refresh then
            self.Page:Refresh()
        end
    end

    local function setExpanded(value)
        expanded = value == true and hasChildren
        childHolder.Visible = expanded
        expander.Text = expanded and "v" or ">"
        object:_refresh()
    end

    local function markHasChildren()
        hasChildren = true
        expander.Visible = true
        childHolder.Visible = expanded
        object:_refresh()
    end

    function object:Set(value)
        self.Value = value == true
        setFlag(self.Flag, self.Value)
        updateSwitch(track, knob, switchGlow, self.Value)
        switchGlow.Visible = self.Value
        labelButton.TextColor3 = self.Value and Library.Theme.Text or Library.Theme.Muted
        setCallback(data.Callback, self.Value)
    end

    function object:SetExpanded(value)
        setExpanded(value)
    end

    function object:ToggleExpanded()
        setExpanded(not expanded)
    end

    local function createChild(method, childData)
        markHasChildren()
        local child = Section[method](object, childData or {})
        table.insert(object.Children, child)
        task.defer(function()
            object:_refresh()
        end)
        return child
    end

    function object:Toggle(childData)
        return createChild("Toggle", childData)
    end

    function object:Slider(childData)
        return createChild("Slider", childData)
    end

    function object:Dropdown(childData)
        return createChild("Dropdown", childData)
    end

    function object:Colorpicker(childData)
        return createChild("Colorpicker", childData)
    end

    object.ColorPicker = object.Colorpicker

    function object:Keybind(childData)
        return createChild("Keybind", childData)
    end

    function object:Button(childData)
        return createChild("Button", childData)
    end

    function object:Textbox(childData)
        return createChild("Textbox", childData)
    end

    registerElement(object.Flag, object)
    setFlag(object.Flag, object.Value)
    updateSwitch(track, knob, switchGlow, object.Value)
    switchGlow.Visible = object.Value
    labelButton.TextColor3 = object.Value and Library.Theme.Text or Library.Theme.Muted

    connect(button.MouseButton1Click, function()
        object:Set(not object.Value)
    end)

    connect(labelButton.MouseButton1Click, function()
        if hasChildren then
            object:ToggleExpanded()
        else
            object:Set(not object.Value)
        end
    end)

    connect(childLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        object:_refresh()
    end)

    return object
end

function Section:Button(data)
    data = data or {}
    local row = self:_createRow(36)

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(13, 15, 23),
        Font = fontWeight("bold"),
        Text = data.Name or "Button",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = row,
    }, {corner(7), stroke(Library.Theme.StrokeSoft, 1, 0.2)})

    bindHover(button, {BackgroundColor3 = Color3.fromRGB(20, 23, 34)}, {BackgroundColor3 = Color3.fromRGB(13, 15, 23)})

    local object = {
        Type = "Button",
        Flag = data.Flag,
        Frame = row,
        Button = button,
    }

    function object:SetText(text)
        button.Text = tostring(text or "")
    end

    connect(button.MouseButton1Click, function()
        setCallback(data.Callback)
    end)

    registerElement(object.Flag, object)
    return object
end

function Section:Textbox(data)
    data = data or {}
    local row = self:_createRow(42)

    local label = textLabel(data.Name or "Textbox", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(0, 132, 0, 42)
    label.Parent = row

    local box = create("TextBox", {
        BackgroundColor3 = Color3.fromRGB(9, 11, 17),
        ClearTextOnFocus = data.ClearTextOnFocus == true,
        Font = fontWeight(),
        PlaceholderText = data.Placeholder or "",
        PlaceholderColor3 = Library.Theme.Muted,
        Position = UDim2.new(0, 145, 0, 4),
        Size = UDim2.new(1, -147, 0, 34),
        Text = tostring(data.Default or ""),
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    }, {corner(7), stroke(Color3.fromRGB(25, 27, 38), 1, 0.15), padding(10, 0, 10, 0)})

    local object = {
        Type = "Textbox",
        Value = box.Text,
        Flag = data.Flag,
        Textbox = box,
    }

    function object:Set(value)
        self.Value = tostring(value or "")
        box.Text = self.Value
        setFlag(self.Flag, self.Value)
        setCallback(data.Callback, self.Value)
    end

    connect(box.FocusLost, function()
        object:Set(box.Text)
    end)

    registerElement(object.Flag, object)
    setFlag(object.Flag, object.Value)
    return object
end

function Section:Slider(data)
    data = data or {}
    local minValue = data.Min or 0
    local maxValue = data.Max or 100
    local decimals = data.Decimals or 0
    local row = self:_createRow(50)

    local label = textLabel(data.Name or "Slider", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(0, 156, 1, 0)
    label.Parent = row

    local valueBox = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 11, 17),
        Position = UDim2.new(1, -76, 0.5, -16),
        Size = UDim2.fromOffset(72, 32),
        Parent = row,
    }, {corner(7), stroke(Color3.fromRGB(25, 27, 38), 1, 0.15)})

    local valueText = textLabel("", 13, Library.Theme.Text, false)
    valueText.Size = UDim2.fromScale(1, 1)
    valueText.TextXAlignment = Enum.TextXAlignment.Center
    valueText.Parent = valueBox

    local track = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(7, 8, 12),
        Position = UDim2.new(0, 166, 0.5, -4),
        Size = UDim2.new(1, -258, 0, 8),
        Parent = row,
    }, {corner(8), stroke(Library.Theme.StrokeSoft, 1, 0.35)})

    local trackGlow = create("Frame", {
        BackgroundColor3 = Library.Theme.Glow,
        BackgroundTransparency = 0.86,
        Position = UDim2.fromOffset(-3, -3),
        Size = UDim2.new(1, 6, 1, 6),
        ZIndex = 0,
        Parent = track,
    }, {corner(10)})

    local fill = create("Frame", {
        BackgroundColor3 = Library.Theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = track,
    }, {corner(4)})

    local knob = create("Frame", {
        BackgroundColor3 = Library.Theme.Accent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(16, 16),
        Parent = track,
    }, {corner(7)})

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Position = UDim2.new(0, 166, 0, 0),
        Size = UDim2.new(1, -258, 1, 0),
        Parent = row,
    })

    local object = {
        Type = "Slider",
        Value = clampNumber(data.Default or minValue, minValue, maxValue),
        Flag = data.Flag,
        Min = minValue,
        Max = maxValue,
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

        tween(fill, {Size = UDim2.new(percent, 0, 1, 0)}, dragging and 0.08 or 0.18)
        tween(knob, {Position = UDim2.fromScale(percent, 0.5)}, dragging and 0.08 or 0.18)
        tween(trackGlow, {BackgroundTransparency = dragging and 0.76 or 0.86}, 0.12)
        valueText.Text = formatNumber(object.Value, decimals, data.Suffix)

        setFlag(object.Flag, object.Value)

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

    registerElement(object.Flag, object)

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
    local row = self:_createRow(42)
    local items = data.Items or {}
    local open = false
    local searchText = ""
    local multi = data.Multi == true or type(data.Default) == "table"

    local label = textLabel(data.Name or "Dropdown", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(0, 132, 0, 42)
    label.Parent = row

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(9, 11, 17),
        Position = UDim2.new(0, 145, 0, 4),
        Size = UDim2.new(1, -147, 0, 34),
        Text = "",
        Parent = row,
    }, {corner(7), stroke(Color3.fromRGB(25, 27, 38), 1, 0.15)})

    local selectedText = textLabel("", 14, Library.Theme.Text, false)
    selectedText.Position = UDim2.fromOffset(12, 0)
    selectedText.Size = UDim2.new(1, -38, 1, 0)
    selectedText.Parent = button

    local arrow = textLabel("v", 14, Library.Theme.Muted, true)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.Size = UDim2.fromOffset(20, 34)
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Parent = button

    local optionHolder = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 11, 17),
        Position = UDim2.new(0, 145, 0, 43),
        Size = UDim2.new(1, -147, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 30,
        Parent = row,
    }, {corner(7), stroke(Color3.fromRGB(25, 27, 38), 1, 0.15), listLayout(0)})

    local searchBox
    if data.Search ~= false then
        searchBox = create("TextBox", {
            BackgroundColor3 = Color3.fromRGB(7, 8, 12),
            ClearTextOnFocus = false,
            Font = fontWeight(),
            PlaceholderText = "Search...",
            PlaceholderColor3 = Library.Theme.Muted,
            Text = "",
            TextColor3 = Library.Theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = 0,
            ZIndex = 31,
            Parent = optionHolder,
        }, {padding(10, 0, 10, 0)})
    end

    local object = {
        Type = "Dropdown",
        Value = multi and copyArray(data.Default) or (data.Default or items[1]),
        Items = items,
        Flag = data.Flag,
        Multi = multi,
    }

    local function filteredItems()
        local result = {}
        local needle = string.lower(searchText or "")
        for _, item in ipairs(object.Items or {}) do
            local text = tostring(item)
            if needle == "" or string.find(string.lower(text), needle, 1, true) then
                table.insert(result, item)
            end
        end
        return result
    end

    local function getDisplayValue()
        if object.Multi then
            return joinValues(object.Value)
        end
        return tostring(object.Value or "")
    end

    local function updateDropdownHeight()
        local visibleItems = filteredItems()
        local searchHeight = searchBox and 30 or 0
        local height = math.min(#visibleItems * 28 + searchHeight, 226)
        optionHolder.Size = UDim2.new(1, -147, 0, open and height or 0)
        row.Size = UDim2.new(1, 0, 0, open and (48 + height) or 42)
    end

    local function rebuild()
        for _, child in ipairs(optionHolder:GetChildren()) do
            if child:IsA("GuiObject") and child ~= searchBox then
                child:Destroy()
            end
        end

        local visibleItems = filteredItems()
        for index, item in ipairs(visibleItems) do
            local selected = object.Multi and containsValue(object.Value, item) or object.Value == item
            local option = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = selected and Color3.fromRGB(30, 22, 49) or Color3.fromRGB(9, 11, 17),
                BorderSizePixel = 0,
                Font = fontWeight(),
                Text = object.Multi and ((selected and "[x] " or "[ ] ") .. tostring(item)) or tostring(item),
                TextColor3 = selected and Library.Theme.Text or Library.Theme.Muted,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 28),
                LayoutOrder = index + 1,
                ZIndex = 31,
                Parent = optionHolder,
            })
            create("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = option})

            bindHover(option, {BackgroundColor3 = Color3.fromRGB(18, 20, 30), TextColor3 = Library.Theme.Text}, {BackgroundColor3 = Color3.fromRGB(9, 11, 17), TextColor3 = Library.Theme.Muted})
            connect(option.MouseButton1Click, function()
                if object.Multi then
                    local values = copyArray(object.Value)
                    if containsValue(values, item) then
                        removeValue(values, item)
                    else
                        table.insert(values, item)
                    end
                    object:Set(values)
                    rebuild()
                    updateDropdownHeight()
                else
                    object:Set(item)
                    open = false
                    optionHolder.Visible = false
                    row.Size = UDim2.new(1, 0, 0, 42)
                    arrow.Text = "v"
                    self:_refresh()
                end
            end)
        end

        updateDropdownHeight()
    end

    function object:Set(value)
        if self.Multi then
            self.Value = copyArray(value)
        else
            self.Value = value
        end

        selectedText.Text = getDisplayValue()
        setFlag(self.Flag, self.Value)
        setCallback(data.Callback, self.Value)
    end

    function object:Refresh(newItems, selected)
        self.Items = newItems or {}
        if selected ~= nil then
            self:Set(selected)
        end
        rebuild()
    end

    function object:SetOptions(newItems, selected)
        return self:Refresh(newItems, selected)
    end

    registerElement(object.Flag, object)
    setFlag(object.Flag, object.Value)
    selectedText.Text = getDisplayValue()

    rebuild()

    if searchBox then
        connect(searchBox:GetPropertyChangedSignal("Text"), function()
            searchText = searchBox.Text
            rebuild()
        end)
    end

    connect(button.MouseButton1Click, function()
        open = not open
        optionHolder.Visible = open
        arrow.Text = open and "^" or "v"
        updateDropdownHeight()
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
        Size = UDim2.new(1, 0, 0, data.Alpha ~= false and 129 or 98),
        Visible = false,
        Parent = row,
    })

    local object = {
        Type = "Colorpicker",
        Value = data.Default or Library.Theme.Accent,
        Alpha = data.Alpha ~= nil and data.Alpha or 1,
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
        setFlag(object.Flag, {Color = object.Value, Alpha = object.Alpha})
        if fire ~= false then
            setCallback(data.Callback, object.Value, object.Alpha)
        end
    end

    local function miniSlider(name, index, maxValue, getValue, setValue)
        maxValue = maxValue or 255
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
            Size = UDim2.fromScale(getValue() / maxValue, 1),
            Parent = track,
        }, {corner(4)})

        local valueText = textLabel(tostring(getValue()), 12, Library.Theme.Text, false)
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
            setValue(math.floor(alpha * maxValue + 0.5))
            fill.Size = UDim2.fromScale(alpha, 1)
            valueText.Text = tostring(getValue())
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

    miniSlider("R", 1, 255, function() return rgb.R end, function(value) rgb.R = value end)
    miniSlider("G", 2, 255, function() return rgb.G end, function(value) rgb.G = value end)
    miniSlider("B", 3, 255, function() return rgb.B end, function(value) rgb.B = value end)
    if data.Alpha ~= false then
        miniSlider("A", 4, 100, function() return math.floor(object.Alpha * 100 + 0.5) end, function(value) object.Alpha = clampNumber(value / 100, 0, 1) end)
    end

    function object:Set(value, alpha)
        if type(value) == "table" and value.Color ~= nil then
            alpha = value.Alpha
            value = value.Color
        end

        if typeof(value) ~= "Color3" then
            value = self.Value or Library.Theme.Accent
        end

        self.Value = value
        rgb.R = math.floor(value.R * 255 + 0.5)
        rgb.G = math.floor(value.G * 255 + 0.5)
        rgb.B = math.floor(value.B * 255 + 0.5)
        if alpha ~= nil then
            self.Alpha = clampNumber(alpha, 0, 1)
        end
        applyColor(true)
    end

    registerElement(object.Flag, object)
    setFlag(object.Flag, {Color = object.Value, Alpha = object.Alpha})

    connect(swatchButton.MouseButton1Click, function()
        open = not open
        picker.Visible = open
        row.Size = UDim2.new(1, 0, 0, open and (data.Alpha ~= false and 173 or 142) or 38)
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
    local mode = data.Mode or "Toggle"

    local label = textLabel(data.Name or "Keybind", 14, Library.Theme.Muted, false)
    label.Size = UDim2.new(1, -118, 1, 0)
    label.Parent = row

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        Position = UDim2.new(1, -108, 0.5, -15),
        Size = UDim2.fromOffset(104, 30),
        Font = fontWeight(),
        Text = currentKey and currentKey.Name or "None",
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        Parent = row,
    }, {corner(7), stroke(Library.Theme.StrokeSoft, 1, 0.2)})

    local object

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
            setFlag(data.Flag, {Key = currentKey, Mode = mode, Value = state})
            return
        end

        if currentKey and input.KeyCode == currentKey then
            if mode == "Toggle" then
                state = not state
                if object then
                    object.Value = state
                end
                setFlag(data.Flag, {Key = currentKey, Mode = mode, Value = state})
                setCallback(data.Callback, state)
            elseif mode == "Hold" then
                state = true
                if object then
                    object.Value = true
                end
                setFlag(data.Flag, {Key = currentKey, Mode = mode, Value = true})
                setCallback(data.Callback, true)
            elseif mode == "Always" then
                state = true
                if object then
                    object.Value = true
                end
                setFlag(data.Flag, {Key = currentKey, Mode = mode, Value = true})
                setCallback(data.Callback, true)
            else
                setCallback(data.Callback, true)
            end
        end
    end)

    connect(UserInputService.InputEnded, function(input, gameProcessed)
        if gameProcessed or waiting then
            return
        end

        if currentKey and input.KeyCode == currentKey and mode == "Hold" then
            state = false
            if object then
                object.Value = false
            end
            setFlag(data.Flag, {Key = currentKey, Mode = mode, Value = false})
            setCallback(data.Callback, false)
        end
    end)

    object = {
        Type = "Keybind",
        Key = currentKey,
        Value = mode == "Always",
        Mode = mode,
        Flag = data.Flag,
        Set = function(self, key)
            if type(key) == "table" and key.Key ~= nil then
                mode = key.Mode or mode
                self.Mode = mode
                state = key.Value == true
                self.Value = state
                key = key.Key
            end
            currentKey = key
            self.Key = key
            self.Value = state
            button.Text = key and key.Name or "None"
            setFlag(self.Flag, {Key = currentKey, Mode = mode, Value = state})
        end,
    }

    function object:SetMode(newMode)
        mode = newMode or mode
        self.Mode = mode
        if mode == "Always" then
            state = true
            self.Value = true
            setCallback(data.Callback, true)
        elseif mode == "Hold" then
            state = false
            self.Value = false
        end
        setFlag(self.Flag, {Key = currentKey, Mode = mode, Value = state})
    end

    registerElement(object.Flag, object)
    setFlag(object.Flag, {Key = currentKey, Mode = mode, Value = state})

    if mode == "Always" then
        task.defer(function()
            setCallback(data.Callback, true)
        end)
    end

    return object
end

local Page = {}
Page.__index = Page

function Page:Refresh()
    local leftHeight = self.LeftLayout.AbsoluteContentSize.Y
    local rightHeight = self.RightLayout.AbsoluteContentSize.Y
    local height = math.max(leftHeight, rightHeight, 1)

    self.LeftColumn.Size = UDim2.new(0.5, -8, 0, leftHeight)
    self.RightColumn.Size = UDim2.new(0.5, -8, 0, rightHeight)
    self.Columns.Size = UDim2.new(1, -4, 0, height)
    self.Scroll.CanvasSize = UDim2.fromOffset(0, height + 28)
end

function Page:Section(data)
    data = data or {}
    local parent = data.Side == 2 and self.RightColumn or self.LeftColumn

    local card = create("Frame", {
        BackgroundColor3 = Library.Theme.Panel,
        BackgroundTransparency = 0.04,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    }, {
        corner(8),
        stroke(Library.Theme.StrokeSoft, 1, 0.28),
        padding(20, 17, 20, 20),
        listLayout(10),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        Parent = card,
    })

    local icon = textLabel(getSectionIcon(data.Name), 21, Library.Theme.Accent, true)
    icon.Size = UDim2.fromOffset(26, 28)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = header

    local title = textLabel(data.Name or "Section", 17, Library.Theme.Accent, true)
    title.Position = UDim2.fromOffset(34, 0)
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
    local wasOpen = self.IsOpen == true
    self.IsOpen = open == true

    if self.IsOpen ~= wasOpen then
        setPlayerMovementLocked(self.IsOpen)
    end

    if self.Gui then
        if self.IsOpen then
            self.Gui.Enabled = true
            if self.Main and self.Scale and Library.AnimationsEnabled then
                self.Scale.Scale = math.max(Library.CurrentScale * 0.96, 0.01)
                self.Main.BackgroundTransparency = 0.14
                tween(self.Scale, {Scale = Library.CurrentScale}, 0.18)
                tween(self.Main, {BackgroundTransparency = 0}, 0.18)
            end
        elseif self.Main and self.Scale and Library.AnimationsEnabled then
            tween(self.Scale, {Scale = math.max(Library.CurrentScale * 0.96, 0.01)}, 0.12)
            tween(self.Main, {BackgroundTransparency = 0.18}, 0.12)
            task.delay(0.13, function()
                if self.Gui and not self.IsOpen then
                    self.Gui.Enabled = false
                    self.Scale.Scale = Library.CurrentScale
                    self.Main.BackgroundTransparency = 0
                end
            end)
        else
            self.Gui.Enabled = self.IsOpen
        end
    end
end

function Window:_selectPage(page)
    self.ActivePage = page

    for _, item in ipairs(self.Pages) do
        local active = item == page
        item.Scroll.Visible = active
        tween(item.SideButton, {
            BackgroundTransparency = active and 0.12 or 1,
            TextColor3 = active and Library.Theme.Text or Library.Theme.Muted,
        }, 0.16)
        tween(item.TopButton, {
            TextColor3 = active and Library.Theme.Accent or Library.Theme.Muted,
        }, 0.16)
        item.TopAccent.Visible = active

        if item.SideIcon then
            tween(item.SideIcon, {TextColor3 = active and Library.Theme.Accent or Library.Theme.Muted}, 0.16)
        end

        if item.SideGlow then
            item.SideGlow.Visible = active
            tween(item.SideGlow, {BackgroundTransparency = active and 0.86 or 1}, 0.16)
        end

        if item.TopAccent then
            item.TopAccent.Size = active and UDim2.new(1, -16, 0, 3) or UDim2.new(0, 0, 0, 3)
        end
    end

    if page.Scroll and Library.AnimationsEnabled then
        page.Scroll.CanvasPosition = Vector2.new(0, 0)
    end

    page:Refresh()
end

function Window:Page(data)
    data = data or {}
    local index = #self.Pages + 1

    local sideButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(28, 24, 43),
        BackgroundTransparency = 1,
        Font = fontWeight("bold"),
        Text = data.Name or ("Page " .. tostring(index)),
        TextColor3 = Library.Theme.Muted,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = self.SideList,
    }, {corner(8), padding(62, 0, 8, 0), stroke(Library.Theme.Stroke, 1, 0.42)})

    local sideGlow = create("Frame", {
        BackgroundColor3 = Library.Theme.Glow,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(-6, -4),
        Size = UDim2.new(1, 12, 1, 8),
        Visible = false,
        ZIndex = 0,
        Parent = sideButton,
    }, {corner(10)})

    local sideIcon = textLabel(getPageIcon(data.Name), 25, Library.Theme.Muted, true)
    sideIcon.Position = UDim2.fromOffset(18, 0)
    sideIcon.Size = UDim2.fromOffset(28, 58)
    sideIcon.TextXAlignment = Enum.TextXAlignment.Center
    sideIcon.Parent = sideButton

    local topButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = fontWeight("bold"),
        Text = getPageIcon(data.Name) .. "   " .. (data.Name or ("Page " .. tostring(index))),
        TextColor3 = Library.Theme.Muted,
        TextSize = 16,
        Size = UDim2.fromOffset(math.max(132, (#tostring(data.Name or "") * 8) + 58), 58),
        Parent = self.TopTabs,
    })

    local topAccent = create("Frame", {
        BackgroundColor3 = Library.Theme.Accent,
        Position = UDim2.new(0, 8, 1, -4),
        Size = UDim2.new(1, -16, 0, 3),
        Visible = false,
        Parent = topButton,
    }, {corner(3)})

    local scroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Theme.Accent,
        Position = UDim2.fromOffset(0, 82),
        Size = UDim2.new(1, 0, 1, -82),
        CanvasSize = UDim2.fromOffset(0, 0),
        Visible = false,
        Parent = self.Content,
    })

    local columns = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -4, 0, 0),
        Parent = scroll,
    })

    local leftColumn = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0.5, -8, 0, 0),
        Parent = columns,
    }, {listLayout(10)})

    local rightColumn = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 8, 0, 0),
        Size = UDim2.new(0.5, -8, 0, 0),
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
        SideGlow = sideGlow,
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
        Name = "UiLibrary",
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
    local width = math.min(1490, math.max(1040, viewport.X - 48))
    local height = math.min(980, math.max(720, viewport.Y - 48))

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Background,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        Parent = gui,
    }, {corner(18), stroke(self.Theme.Stroke, 1, 0)})

    local mainGlow = addSoftGlow(main, 18, self.Theme.Glow, 0.9)

    local uiScale = create("UIScale", {
        Scale = normalizeScale(self.CurrentScale),
        Parent = main,
    })
    self.CurrentScale = uiScale.Scale

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
        BackgroundTransparency = 0.04,
        Size = UDim2.new(0, 268, 1, 0),
        Parent = main,
    }, {corner(18)})

    create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 23, 34),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = sidebar,
    })

    local logoArea = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 228),
        Parent = sidebar,
    })

    for _, dot in ipairs({
        {36, 56, 4, 0.4},
        {72, 34, 3, 0.55},
        {202, 64, 3, 0.5},
        {220, 118, 2, 0.62},
    }) do
        local sparkle = create("Frame", {
            BackgroundColor3 = self.Theme.Accent,
            BackgroundTransparency = dot[4],
            Position = UDim2.fromOffset(dot[1], dot[2]),
            Size = UDim2.fromOffset(dot[3], dot[3]),
            Parent = logoArea,
        }, {corner(dot[3])})

        if self.AnimationsEnabled then
            task.spawn(function()
                while sparkle.Parent do
                    tween(sparkle, {BackgroundTransparency = math.min(dot[4] + 0.25, 0.9)}, 0.8)
                    task.wait(0.8)
                    tween(sparkle, {BackgroundTransparency = dot[4]}, 0.8)
                    task.wait(0.8)
                end
            end)
        end
    end

    local logo
    local logoImage = data.Logo or "rbxassetid://108498041910348"
    if logoImage then
        logo = create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = normalizeImage(logoImage),
            ImageColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 34),
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromOffset(134, 112),
            Parent = logoArea,
        })
    end

    local displayName = data.Name or "UiLib"
    local nameHolder = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 154),
        Size = UDim2.new(1, 0, 0, 34),
        Parent = logoArea,
    })

    local nameFont = fontWeight("bold")
    local before, after = displayName, ""
    local dotPosition = string.find(displayName, "%.")
    if dotPosition then
        before = string.sub(displayName, 1, dotPosition)
        after = string.sub(displayName, dotPosition + 1)
    end

    local beforeSize = TextService:GetTextSize(before, 28, nameFont, Vector2.new(400, 34)).X
    local afterSize = TextService:GetTextSize(after, 28, nameFont, Vector2.new(400, 34)).X
    local totalNameWidth = beforeSize + afterSize

    local name = textLabel(before, 28, self.Theme.Text, true)
    name.Font = nameFont
    name.Position = UDim2.new(0.5, -totalNameWidth / 2, 0, 0)
    name.Size = UDim2.fromOffset(beforeSize, 34)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = nameHolder

    local nameAccent = textLabel(after, 28, self.Theme.Accent, true)
    nameAccent.Font = nameFont
    nameAccent.Position = UDim2.new(0.5, -totalNameWidth / 2 + beforeSize, 0, 0)
    nameAccent.Size = UDim2.fromOffset(afterSize, 34)
    nameAccent.TextXAlignment = Enum.TextXAlignment.Left
    nameAccent.Parent = nameHolder

    local subName = textLabel(data.SubName or "uilib", 14, self.Theme.Accent, true)
    subName.TextXAlignment = Enum.TextXAlignment.Center
    subName.Position = UDim2.fromOffset(0, 190)
    subName.Size = UDim2.new(1, 0, 0, 20)
    subName.Parent = logoArea

    local sideList = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 250),
        Size = UDim2.new(1, -44, 1, -378),
        Parent = sidebar,
    }, {listLayout(9)})

    local status = create("Frame", {
        BackgroundColor3 = self.Theme.PanelLight,
        BackgroundTransparency = 0.08,
        Position = UDim2.new(0, 22, 1, -118),
        Size = UDim2.new(1, -44, 0, 92),
        Parent = sidebar,
    }, {corner(8), stroke(self.Theme.StrokeSoft, 1, 0.25), padding(18, 13, 18, 13)})

    local statusTitle = textLabel(data.Name or "UiLib", 15, self.Theme.Accent, true)
    statusTitle.Size = UDim2.new(1, -18, 0, 22)
    statusTitle.Parent = status

    local statusDot = create("Frame", {
        BackgroundColor3 = self.Theme.Green,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 8),
        Size = UDim2.fromOffset(12, 12),
        Parent = status,
    }, {corner(9)})

    local version = textLabel("Version: 1.0.0", 13, self.Theme.Muted, false)
    version.Position = UDim2.fromOffset(0, 30)
    version.Size = UDim2.new(1, 0, 0, 18)
    version.Parent = status

    local injected = textLabel("Status: Ready", 13, self.Theme.Green, false)
    injected.Position = UDim2.fromOffset(0, 58)
    injected.Size = UDim2.new(1, 0, 0, 18)
    injected.Parent = status

    local watermark = create("Frame", {
        BackgroundColor3 = self.Theme.PanelLight,
        BackgroundTransparency = 0.08,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(220, 32),
        Visible = self.WatermarkEnabled,
        Parent = gui,
    }, {corner(8), stroke(self.Theme.Stroke, 1, 0.2), padding(10, 0, 10, 0)})

    local watermarkText = textLabel((data.Name or "UiLib") .. " | loaded", 13, self.Theme.Text, true)
    watermarkText.Size = UDim2.fromScale(1, 1)
    watermarkText.Parent = watermark

    local watermarkScale = create("UIScale", {
        Scale = normalizeScale(self.CurrentScale),
        Parent = watermark,
    })

    local content = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(290, 22),
        Size = UDim2.new(1, -312, 1, -44),
        Parent = main,
    })

    local top = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 68),
        Parent = content,
    })

    local topTabs = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ClipsDescendants = true,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        Size = UDim2.new(1, -190, 1, 0),
        Parent = top,
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 18),
        }),
    })

    local topTabsLayout = topTabs:FindFirstChildOfClass("UIListLayout")
    connect(topTabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        topTabs.CanvasSize = UDim2.fromOffset(topTabsLayout.AbsoluteContentSize.X + 8, 0)
    end)

    local product = textLabel(data.HeaderText or "Interface", 16, self.Theme.Text, true)
    product.AnchorPoint = Vector2.new(1, 0)
    product.Position = UDim2.new(1, -38, 0, 23)
    product.Size = UDim2.fromOffset(142, 28)
    product.TextXAlignment = Enum.TextXAlignment.Right
    product.Parent = top

    create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -148, 0, 32),
        Size = UDim2.fromOffset(12, 12),
        Parent = top,
    }, {corner(9)})

    local close = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = fontWeight("bold"),
        Text = "X",
        TextColor3 = self.Theme.Muted,
        TextSize = 18,
        Position = UDim2.new(1, -24, 0, 13),
        Size = UDim2.fromOffset(28, 28),
        Parent = top,
    })

    local minimize = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = fontWeight("bold"),
        Text = "-",
        TextColor3 = self.Theme.Muted,
        TextSize = 20,
        Position = UDim2.new(1, -64, 0, 12),
        Size = UDim2.fromOffset(28, 28),
        Parent = top,
    })

    create("Frame", {
        BackgroundColor3 = self.Theme.StrokeSoft,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 78),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = content,
    })

    local window = setmetatable({
        Gui = gui,
        Main = main,
        MainGlow = mainGlow,
        Scale = uiScale,
        Watermark = watermark,
        WatermarkScale = watermarkScale,
        SideList = sideList,
        TopTabs = topTabs,
        Content = content,
        Pages = {},
        ActivePage = nil,
        IsOpen = true,
    }, Window)

    setPlayerMovementLocked(true)

    table.insert(self.Windows, window)

    connect(close.MouseButton1Click, function()
        window:SetOpen(false)
    end)

    connect(minimize.MouseButton1Click, function()
        window:SetOpen(false)
    end)

    makeDraggable(top, main)

    local menuKeybind = data.MenuKeybind or Enum.KeyCode.RightShift
    connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if menuKeybind and input.KeyCode == menuKeybind then
            window:SetOpen(not window.IsOpen)
        end
    end)

    return window
end

function Library:Log(text, duration, color)
    if self.LogsEnabled == false then
        return
    end

    local panel, list = ensureLogger()
    panel.Visible = self.LogsVisible ~= false

    self.LogCounter = self.LogCounter + 1
    local message = tostring(text)
    local textSize = TextService:GetTextSize(message, 13, fontWeight(), Vector2.new(420, math.huge))
    local width = clampNumber(textSize.X + 52, 190, 360)

    local toast = create("Frame", {
        BackgroundColor3 = self.Theme.PanelLight,
        BackgroundTransparency = 0.06,
        Position = UDim2.new(0, 0, 0, -48),
        Size = UDim2.fromOffset(width, 44),
        LayoutOrder = self.LogCounter,
        Parent = list,
    }, {corner(8), stroke(self.Theme.Stroke, 1, 0.15), padding(12, 0, 12, 0)})

    local accent = create("Frame", {
        BackgroundColor3 = color or self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 9),
        Size = UDim2.fromOffset(3, 26),
        Parent = toast,
    }, {corner(3)})

    local label = textLabel(message, 13, color or self.Theme.Text, false)
    label.Position = UDim2.fromOffset(10, 0)
    label.Size = UDim2.fromScale(1, 1)
    label.Parent = toast

    table.insert(self.ActiveLogs, 1, toast)
    updateLoggerStack()
    tween(toast, {BackgroundTransparency = 0.06}, 0.18)

    task.delay(duration or 3, function()
        if toast and toast.Parent then
            tween(toast, {BackgroundTransparency = 1}, 0.2)
            tween(label, {TextTransparency = 1}, 0.2)
            tween(accent, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.22)
            if toast and toast.Parent then
                removeLogToast(toast)
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
    local menuSection = page:Section({Name = "Menu", Side = 1})
    local configSection = page:Section({Name = "Configs", Side = 2})

    menuSection:Toggle({
        Name = "Logs",
        Default = self.LogsEnabled,
        Callback = function(value)
            self.LogsEnabled = value
            if self.LoggerPanel then
                self.LoggerPanel.Visible = value and self.LogsVisible ~= false
            end
        end,
    })

    menuSection:Toggle({
        Name = "Watermark",
        Default = self.WatermarkEnabled,
        Callback = function(value)
            self:SetWatermarkVisible(value)
        end,
    })

    menuSection:Dropdown({
        Name = "Menu Scale",
        Flag = "Library_MenuScale",
        Items = {"0.5x", "0.75x", "1x", "1.25x", "1.5x"},
        Default = scaleLabel(self.CurrentScale),
        Search = false,
        Callback = function(value)
            self:SetScale(value)
        end,
    })

    local selectedConfig = "default"
    local configDropdown

    local nameBox = configSection:Textbox({
        Name = "Name",
        Default = selectedConfig,
        Placeholder = "default",
        Callback = function(value)
            selectedConfig = normalizeConfigName(value)
        end,
    })

    configDropdown = configSection:Dropdown({
        Name = "Profile",
        Items = getConfigNames(),
        Default = selectedConfig,
        Search = true,
        Callback = function(value)
            selectedConfig = normalizeConfigName(value)
            nameBox:Set(selectedConfig)
        end,
    })

    local function refreshConfigs(selected)
        local names = getConfigNames()
        configDropdown:Refresh(names, selected or selectedConfig)
    end

    configSection:Button({
        Name = "Save",
        Callback = function()
            local ok, result = self:SaveConfig(selectedConfig)
            self:Log(ok and ("Saved config: " .. result) or ("Save failed: " .. tostring(result)), 3, ok and self.Theme.Green or Color3.fromRGB(255, 90, 90))
            refreshConfigs(ok and result or selectedConfig)
        end,
    })

    configSection:Button({
        Name = "Load",
        Callback = function()
            local ok, result = self:LoadConfig(selectedConfig)
            self:Log(ok and ("Loaded config: " .. result) or ("Load failed: " .. tostring(result)), 3, ok and self.Theme.Green or Color3.fromRGB(255, 90, 90))
        end,
    })

    configSection:Button({
        Name = "Delete",
        Callback = function()
            local ok, result = self:DeleteConfig(selectedConfig)
            self:Log(ok and ("Deleted config: " .. result) or ("Delete failed: " .. tostring(result)), 3, ok and self.Theme.Green or Color3.fromRGB(255, 90, 90))
            refreshConfigs("default")
        end,
    })
end

function Library:Unload()
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    clearTable(self.Connections)

    for _, window in ipairs(self.Windows) do
        if window.Gui then
            if window.IsOpen then
                setPlayerMovementLocked(false)
                window.IsOpen = false
            end
            window.Gui:Destroy()
        end
    end

    clearTable(self.Windows)
    clearTable(self.ActiveLogs)
    clearTable(self.Elements)
    clearTable(self.Flags)
    self.LoggerGui = nil
    self.LoggerPanel = nil
    self.LoggerList = nil
    if self.LoggerScreen then
        self.LoggerScreen:Destroy()
        self.LoggerScreen = nil
    end
    self.Holder = nil
end

return Library
