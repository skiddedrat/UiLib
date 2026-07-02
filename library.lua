--[[
	UILib - Generic Roblox UI Component Library
	Dark theme with purple accents, tabbed sidebar layout.

	USAGE:
		local UILib = loadstring(game:HttpGet("URL_TO_THIS_FILE"))()
		-- or: local UILib = require(path.to.ModuleScript)

		local Window = UILib:CreateWindow({
			Title = "My App",
			SubTitle = "v1.0.0",
		})

		local Tab = Window:CreateTab("Settings")
		local Section = Tab:CreateSection("General")

		Section:Toggle({
			Text = "Enable Feature",
			Default = false,
			Callback = function(value) print(value) end,
		})

		Section:Slider({
			Text = "Volume",
			Min = 0, Max = 100, Default = 50,
			Suffix = "%",
			Callback = function(value) print(value) end,
		})

		Section:Dropdown({
			Text = "Mode",
			Options = {"Easy", "Medium", "Hard"},
			Default = "Easy",
			Callback = function(value) print(value) end,
		})

		Section:Button({
			Text = "Do Thing",
			Callback = function() print("clicked") end,
		})
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Theme ------------------------------------------------------------
local Theme = {
	Background      = Color3.fromRGB(15, 13, 20),
	Sidebar         = Color3.fromRGB(18, 16, 24),
	Panel           = Color3.fromRGB(24, 21, 31),
	PanelLight      = Color3.fromRGB(30, 27, 38),
	Border          = Color3.fromRGB(40, 36, 50),
	Accent          = Color3.fromRGB(147, 92, 255),
	AccentDim       = Color3.fromRGB(90, 60, 160),
	Text            = Color3.fromRGB(235, 233, 240),
	SubText         = Color3.fromRGB(150, 145, 165),
	Toggle_On       = Color3.fromRGB(147, 92, 255),
	Toggle_Off      = Color3.fromRGB(55, 50, 65),
	Font            = Enum.Font.GothamMedium,
	FontBold        = Enum.Font.GothamBold,
}

local function tween(obj, props, time, style, dir)
	local info = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function make(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

--// Dragging helper ---------------------------------------------------
local function makeDraggable(dragHandle, target)
	local dragging = false
	local dragStart, startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// Library root -------------------------------------------------------
local UILib = {}
UILib.__index = UILib

function UILib:CreateWindow(config)
	config = config or {}
	local title = config.Title or "UILib"
	local subTitle = config.SubTitle or ""

	-- destroy any previous instance so re-running doesn't stack windows
	local existing = PlayerGui:FindFirstChild("UILib_ScreenGui")
	if existing then existing:Destroy() end

	local ScreenGui = make("ScreenGui", {
		Name = "UILib_ScreenGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	local Main = make("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(860, 560),
		Position = UDim2.new(0.5, -430, 0.5, -280),
		BackgroundColor3 = Theme.Background,
		Parent = ScreenGui,
	})
	corner(Main, 10)
	stroke(Main, Theme.Border, 1)

	-- Top bar (drag handle + close/minimize)
	local TopBar = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = Main,
	})
	makeDraggable(TopBar, Main)

	local CloseBtn = make("TextButton", {
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -36, 0, 2),
		Parent = TopBar,
	})
	CloseBtn.MouseButton1Click:Connect(function()
		ScreenGui.Enabled = false
	end)
	CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {TextColor3 = Theme.Text}, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {TextColor3 = Theme.SubText}, 0.1) end)

	local MinBtn = make("TextButton", {
		Text = "—",
		Font = Theme.FontBold,
		TextSize = 16,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -66, 0, 2),
		Parent = TopBar,
	})
	local minimized = false
	local fullSize = Main.Size
	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			tween(Main, {Size = UDim2.fromOffset(fullSize.X.Offset, 34)}, 0.2)
		else
			tween(Main, {Size = fullSize}, 0.2)
		end
	end)

	-- Sidebar
	local Sidebar = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 200, 1, -34),
		Position = UDim2.new(0, 0, 0, 34),
		BackgroundColor3 = Theme.Sidebar,
		Parent = Main,
	})
	local sidebarCorner = corner(Sidebar, 10)

	-- mask the right-side corners of the sidebar so only left corners round
	local SidebarMask = make("Frame", {
		Size = UDim2.new(0, 10, 1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = Sidebar,
	})

	local Header = make("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundTransparency = 1,
		Parent = Sidebar,
	})

	make("TextLabel", {
		Text = title,
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -30, 0, 22),
		Position = UDim2.new(0, 16, 0, 14),
		Parent = Header,
	})
	make("TextLabel", {
		Text = subTitle,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -30, 0, 16),
		Position = UDim2.new(0, 16, 0, 38),
		Parent = Header,
	})

	local TabList = make("Frame", {
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, -70),
		Position = UDim2.new(0, 0, 0, 70),
		BackgroundTransparency = 1,
		Parent = Sidebar,
	})
	local TabListLayout = make("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabList,
	})
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = TabList,
	})

	-- Content area
	local Content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -200, 1, -34),
		Position = UDim2.new(0, 200, 0, 34),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local Window = setmetatable({
		ScreenGui = ScreenGui,
		Main = Main,
		TabList = TabList,
		Content = Content,
		Tabs = {},
		_firstTab = nil,
	}, UILib)

	return Window
end

--// Tabs -----------------------------------------------------------

function UILib:CreateTab(name)
	local index = #self.Tabs + 1

	local TabButton = make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.PanelLight,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = index,
		Parent = self.TabList,
	})
	corner(TabButton, 6)

	local Indicator = make("Frame", {
		Size = UDim2.new(0, 3, 0, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		Parent = TabButton,
	})
	corner(Indicator, 2)

	local Label = make("TextLabel", {
		Text = name,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		Parent = TabButton,
	})

	local Page = make("ScrollingFrame", {
		Name = name .. "_Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.Content,
	})
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 20),
		Parent = Page,
	})
	local PageLayout = make("UIListLayout", {
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Page,
	})

	local Tab = setmetatable({
		Button = TabButton,
		Indicator = Indicator,
		Label = Label,
		Page = Page,
		Sections = {},
	}, UILib)

	local function selectTab()
		for _, t in ipairs(self.Tabs) do
			t.Page.Visible = false
			tween(t.Indicator, {BackgroundTransparency = 1}, 0.15)
			tween(t.Label, {TextColor3 = Theme.SubText}, 0.15)
			tween(t.Button, {BackgroundTransparency = 1}, 0.15)
		end
		Page.Visible = true
		tween(Indicator, {BackgroundTransparency = 0}, 0.15)
		tween(Label, {TextColor3 = Theme.Text}, 0.15)
		tween(TabButton, {BackgroundTransparency = 0}, 0.15)
	end

	TabButton.MouseButton1Click:Connect(selectTab)

	table.insert(self.Tabs, Tab)
	if index == 1 then
		selectTab()
	end

	return Tab
end

--// Sections (grouping box within a tab) ----------------------------

function UILib:CreateSection(name)
	local SectionFrame = make("Frame", {
		Name = (name or "Section") .. "_Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Panel,
		LayoutOrder = #self.Sections + 1,
		Parent = self.Page,
	})
	corner(SectionFrame, 8)
	stroke(SectionFrame, Theme.Border, 1)

	if name then
		make("TextLabel", {
			Text = name,
			Font = Theme.FontBold,
			TextSize = 14,
			TextColor3 = Theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -32, 0, 20),
			Position = UDim2.new(0, 16, 0, 14),
			Parent = SectionFrame,
		})
	end

	local Body = make("Frame", {
		Name = "Body",
		Size = UDim2.new(1, -32, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 16, 0, name and 40 or 14),
		BackgroundTransparency = 1,
		Parent = SectionFrame,
	})
	make("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Body,
	})
	make("UIPadding", {
		PaddingBottom = UDim.new(0, 14),
		Parent = Body,
	})

	local Section = setmetatable({
		Frame = SectionFrame,
		Body = Body,
		_count = 0,
	}, UILib)

	table.insert(self.Sections, Section)
	return Section
end

local function nextOrder(section)
	section._count = section._count + 1
	return section._count
end

--// Components -------------------------------------------------------

function UILib:Toggle(config)
	config = config or {}
	local text = config.Text or "Toggle"
	local default = config.Default or false
	local callback = config.Callback or function() end
	local state = default

	local Holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Parent = self.Body,
	})

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -50, 1, 0),
		Parent = Holder,
	})

	local Track = make("Frame", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -38, 0.5, -10),
		BackgroundColor3 = state and Theme.Toggle_On or Theme.Toggle_Off,
		Parent = Holder,
	})
	corner(Track, 10)

	local Knob = make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = Track,
	})
	corner(Knob, 8)

	local Click = make("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = Holder,
	})

	local function setState(v)
		state = v
		tween(Track, {BackgroundColor3 = state and Theme.Toggle_On or Theme.Toggle_Off}, 0.15)
		tween(Knob, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.15)
		callback(state)
	end

	Click.MouseButton1Click:Connect(function()
		setState(not state)
	end)

	if default then callback(state) end

	return {
		Set = setState,
		Get = function() return state end,
	}
end

function UILib:Slider(config)
	config = config or {}
	local text = config.Text or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local default = math.clamp(config.Default or min, min, max)
	local suffix = config.Suffix or ""
	local callback = config.Callback or function() end
	local decimals = config.Decimals or 0

	local Holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Parent = self.Body,
	})

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 18),
		Parent = Holder,
	})

	local ValueLabel = make("TextLabel", {
		Text = tostring(default) .. suffix,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 60, 0, 18),
		Position = UDim2.new(1, -60, 0, 0),
		Parent = Holder,
	})

	local Bar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundColor3 = Theme.Toggle_Off,
		Parent = Holder,
	})
	corner(Bar, 3)

	local function pct(v) return (v - min) / (max - min) end

	local Fill = make("Frame", {
		Size = UDim2.new(pct(default), 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		Parent = Bar,
	})
	corner(Fill, 3)

	local Knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(pct(default), -7, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = Bar,
	})
	corner(Knob, 7)

	local dragging = false
	local value = default

	local function round(v)
		local mult = 10 ^ decimals
		return math.floor(v * mult + 0.5) / mult
	end

	local function update(input)
		local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
		value = round(min + (max - min) * rel)
		Fill.Size = UDim2.new(rel, 0, 1, 0)
		Knob.Position = UDim2.new(rel, -7, 0.5, -7)
		ValueLabel.Text = tostring(value) .. suffix
		callback(value)
	end

	Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)

	return {
		Set = function(v)
			v = math.clamp(v, min, max)
			local rel = pct(v)
			value = v
			Fill.Size = UDim2.new(rel, 0, 1, 0)
			Knob.Position = UDim2.new(rel, -7, 0.5, -7)
			ValueLabel.Text = tostring(v) .. suffix
		end,
		Get = function() return value end,
	}
end

function UILib:Dropdown(config)
	config = config or {}
	local text = config.Text or "Dropdown"
	local options = config.Options or {}
	local default = config.Default or options[1]
	local callback = config.Callback or function() end
	local multi = config.Multi or false

	local selected = default
	local selectedSet = {}
	if multi then
		if type(default) == "table" then
			for _, v in ipairs(default) do selectedSet[v] = true end
		end
	end

	local Holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		ClipsDescendants = false,
		ZIndex = 2,
		Parent = self.Body,
	})

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = Holder,
	})

	local Box = make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Theme.PanelLight,
		ZIndex = 2,
		Parent = Holder,
	})
	corner(Box, 6)
	stroke(Box, Theme.Border, 1)

	local function labelText()
		if multi then
			local names = {}
			for k, v in pairs(selectedSet) do
				if v then table.insert(names, k) end
			end
			return #names > 0 and table.concat(names, ", ") or "None"
		end
		return tostring(selected)
	end

	local SelectedLabel = make("TextLabel", {
		Text = labelText(),
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		ZIndex = 2,
		Parent = Box,
	})

	local Arrow = make("TextLabel", {
		Text = "▾",
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 30),
		Position = UDim2.new(1, -24, 0, 0),
		ZIndex = 2,
		Parent = Box,
	})

	local optionCount = #options
	local ListHeight = math.min(optionCount, 5) * 28

	local List = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 54),
		BackgroundColor3 = Theme.PanelLight,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, optionCount * 28),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 5,
		Parent = Holder,
	})
	corner(List, 6)
	stroke(List, Theme.Border, 1)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = List,
	})

	local open = false
	local function closeList()
		open = false
		tween(List, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
		task.delay(0.15, function() List.Visible = false end)
		tween(Arrow, {Rotation = 0}, 0.15)
	end
	local function openList()
		open = true
		List.Visible = true
		tween(List, {Size = UDim2.new(1, 0, 0, ListHeight)}, 0.15)
		tween(Arrow, {Rotation = 180}, 0.15)
	end

	Box.MouseButton1Click:Connect(function()
		if open then closeList() else openList() end
	end)

	for i, opt in ipairs(options) do
		local OptBtn = make("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			LayoutOrder = i,
			ZIndex = 5,
			Parent = List,
		})
		make("TextLabel", {
			Text = tostring(opt),
			Font = Theme.Font,
			TextSize = 13,
			TextColor3 = (not multi and opt == selected) and Theme.Accent or Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),
			ZIndex = 5,
			Parent = OptBtn,
		})
		OptBtn.MouseEnter:Connect(function() tween(OptBtn, {BackgroundTransparency = 0.85}, 0.1); OptBtn.BackgroundColor3 = Theme.Accent end)
		OptBtn.MouseLeave:Connect(function() tween(OptBtn, {BackgroundTransparency = 1}, 0.1) end)

		OptBtn.MouseButton1Click:Connect(function()
			if multi then
				selectedSet[opt] = not selectedSet[opt]
				SelectedLabel.Text = labelText()
				local result = {}
				for k, v in pairs(selectedSet) do if v then table.insert(result, k) end end
				callback(result)
			else
				selected = opt
				SelectedLabel.Text = labelText()
				callback(selected)
				closeList()
			end
		end)
	end

	if default then callback(multi and (function()
		local r = {}
		for k, v in pairs(selectedSet) do if v then table.insert(r, k) end end
		return r
	end)() or selected) end

	return {
		Set = function(v)
			selected = v
			SelectedLabel.Text = labelText()
		end,
		Get = function() return multi and selectedSet or selected end,
	}
end

function UILib:Colorpicker(config)
	config = config or {}
	local text = config.Text or "Color"
	local default = config.Default or Color3.fromRGB(255, 255, 255)
	local callback = config.Callback or function() end
	local color = default

	local Holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		ZIndex = 3,
		Parent = self.Body,
	})

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		ZIndex = 3,
		Parent = Holder,
	})

	local Swatch = make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(28, 20),
		Position = UDim2.new(1, -28, 0.5, -10),
		ZIndex = 3,
		Parent = Holder,
	})
	corner(Swatch, 5)
	stroke(Swatch, Theme.Border, 1)

	local Panel = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = Theme.PanelLight,
		Visible = false,
		ZIndex = 6,
		Parent = Holder,
	})
	corner(Panel, 6)
	stroke(Panel, Theme.Border, 1)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		Parent = Panel,
	})
	local PanelLayout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Panel,
	})

	local function channelSlider(labelText, initial)
		local Row = make("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 6, Parent = Panel })
		make("TextLabel", {
			Text = labelText, Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
			BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 20), ZIndex = 6, Parent = Row,
		})
		local Bar = make("Frame", {
			Size = UDim2.new(1, -50, 0, 6), Position = UDim2.new(0, 20, 0.5, -3),
			BackgroundColor3 = Theme.Toggle_Off, ZIndex = 6, Parent = Row,
		})
		corner(Bar, 3)
		local Fill = make("Frame", { Size = UDim2.new(initial / 255, 0, 1, 0), BackgroundColor3 = Theme.Accent, ZIndex = 6, Parent = Bar })
		corner(Fill, 3)
		local ValLbl = make("TextLabel", {
			Text = tostring(initial), Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
			BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 20), Position = UDim2.new(1, -30, 0, 0),
			ZIndex = 6, Parent = Row,
		})
		local dragging = false
		local val = initial
		local function upd(input)
			local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
			val = math.floor(rel * 255 + 0.5)
			Fill.Size = UDim2.new(rel, 0, 1, 0)
			ValLbl.Text = tostring(val)
			return val
		end
		Bar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		return Row, function() return val end, function(input)
			if dragging then return upd(input) end
			return nil
		end, function(v)
			val = v
			local rel = v / 255
			Fill.Size = UDim2.new(rel, 0, 1, 0)
			ValLbl.Text = tostring(v)
		end
	end

	local rRow, getR, dragR, setR = channelSlider("R", math.floor(color.R * 255))
	local gRow, getG, dragG, setG = channelSlider("G", math.floor(color.G * 255))
	local bRow, getB, dragB, setB = channelSlider("B", math.floor(color.B * 255))

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local changed = false
			if dragR(input) then changed = true end
			if dragG(input) then changed = true end
			if dragB(input) then changed = true end
			if changed then
				color = Color3.fromRGB(getR(), getG(), getB())
				Swatch.BackgroundColor3 = color
				callback(color)
			end
		end
	end)

	local open = false
	Swatch.MouseButton1Click:Connect(function()
		open = not open
		Panel.Visible = open
		if open then
			task.wait()
			Panel.Size = UDim2.new(1, 0, 0, PanelLayout.AbsoluteContentSize.Y + 20)
		else
			Panel.Size = UDim2.new(1, 0, 0, 0)
		end
	end)

	return {
		Set = function(c)
			color = c
			Swatch.BackgroundColor3 = c
			setR(math.floor(c.R * 255))
			setG(math.floor(c.G * 255))
			setB(math.floor(c.B * 255))
		end,
		Get = function() return color end,
	}
end

function UILib:Keybind(config)
	config = config or {}
	local text = config.Text or "Keybind"
	local default = config.Default or Enum.KeyCode.Unknown
	local callback = config.Callback or function() end
	local currentKey = default
	local listening = false

	local Holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Parent = self.Body,
	})

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		Parent = Holder,
	})

	local KeyBtn = make("TextButton", {
		Text = currentKey.Name,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		AutoButtonColor = false,
		BackgroundColor3 = Theme.PanelLight,
		Size = UDim2.fromOffset(76, 22),
		Position = UDim2.new(1, -76, 0.5, -11),
		Parent = Holder,
	})
	corner(KeyBtn, 5)
	stroke(KeyBtn, Theme.Border, 1)

	KeyBtn.MouseButton1Click:Connect(function()
		listening = true
		KeyBtn.Text = "..."
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			currentKey = input.KeyCode
			KeyBtn.Text = currentKey.Name
			listening = false
			callback(currentKey, "Set")
		elseif not processed and not listening and input.KeyCode == currentKey then
			callback(currentKey, "Down")
		end
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		if not listening and input.KeyCode == currentKey then
			callback(currentKey, "Up")
		end
	end)

	return {
		Set = function(keyCode)
			currentKey = keyCode
			KeyBtn.Text = keyCode.Name
		end,
		Get = function() return currentKey end,
	}
end

function UILib:Button(config)
	config = config or {}
	local text = config.Text or "Button"
	local callback = config.Callback or function() end

	local Btn = make("TextButton", {
		Text = text,
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Accent,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = nextOrder(self),
		Parent = self.Body,
	})
	corner(Btn, 6)

	Btn.MouseEnter:Connect(function() tween(Btn, {BackgroundColor3 = Theme.AccentDim}, 0.1) end)
	Btn.MouseLeave:Connect(function() tween(Btn, {BackgroundColor3 = Theme.Accent}, 0.1) end)
	Btn.MouseButton1Click:Connect(function()
		tween(Btn, {BackgroundColor3 = Theme.AccentDim}, 0.08)
		task.delay(0.08, function() tween(Btn, {BackgroundColor3 = Theme.Accent}, 0.15) end)
		callback()
	end)

	return { Instance = Btn }
end

function UILib:Label(text)
	local Lbl = make("TextLabel", {
		Text = text or "",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(self),
		Parent = self.Body,
	})
	return {
		Set = function(t) Lbl.Text = t end,
		Instance = Lbl,
	}
end

function UILib:Textbox(config)
	config = config or {}
	local text = config.Text or "Input"
	local placeholder = config.Placeholder or ""
	local callback = config.Callback or function() end

	local Holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Parent = self.Body,
	})

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = Holder,
	})

	local Box = make("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Theme.PanelLight,
		Parent = Holder,
	})
	corner(Box, 6)
	stroke(Box, Theme.Border, 1)

	local Input = make("TextBox", {
		Text = "",
		PlaceholderText = placeholder,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		PlaceholderColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Parent = Box,
	})

	Input.FocusLost:Connect(function(enterPressed)
		callback(Input.Text, enterPressed)
	end)

	return {
		Set = function(t) Input.Text = t end,
		Get = function() return Input.Text end,
	}
end

return UILib
