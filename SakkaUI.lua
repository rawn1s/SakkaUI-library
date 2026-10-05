--!strict
--[[
===========================================================================================
	SakkaUI  .  v1.0.0
	Production-ready, strictly-typed Object-Oriented UI framework for Roblox.

	ARCHITECTURE
	  ENGINE  -> hardcoded theme table, tween helpers, layout builders, gradient builders.
	  FACTORY -> Library / Window / Tab / control classes (metatable backed).

	USAGE
	  local Sakka  = require(game.ReplicatedStorage.SakkaUI)
	  local lib    = Sakka.new()
	  local window = lib:CreateWindow({ Title = "Sakka Hub" })
	  local tab    = window:CreateTab("Farming")
	  tab:AddButton({ Text = "Execute", Callback = function() end })

	FLAGS
	  Every interactive control registers itself in <Tab>.Flags[<Name>] = <control object>.
===========================================================================================
]]

-- =========================================================================================
--  1. SERVICES
-- =========================================================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")


-- Loading screen logo asset (assign a 1:1 star-eye PNG asset id)
local STAR_EYE_IMAGE_ID = "rbxassetid://132033501479451"
local LocalPlayer = Players.LocalPlayer

-- =========================================================================================
--  2. PUBLIC TYPES
-- =========================================================================================

export type ButtonConfig = {
	Text: string,
	DependsOn: any?,
	Paid: boolean?,
	PaidBadgeText: string?,
	PaidColor: Color3?,
	Callback: (() -> ())?,
}

export type ToggleConfig = {
	Text: string,
	Default: boolean?,
	DependsOn: any?,
	Paid: boolean?,
	PaidBadgeText: string?,
	PaidColor: Color3?,
	Callback: ((state: boolean) -> ())?,
}

export type SliderConfig = {
	Text: string,
	Min: number,
	Max: number,
	Default: number?,
	Suffix: string?,
	UpdateOnRelease: boolean?,
	DependsOn: any?,
	Paid: boolean?,
	PaidBadgeText: string?,
	PaidColor: Color3?,
	Callback: ((value: number) -> ())?,
}

export type DropdownConfig = {
	Text: string,
	Options: { string },
	Default: string?,
	DependsOn: any?,
	Paid: boolean?,
	PaidBadgeText: string?,
	PaidColor: Color3?,
	Favorites: boolean?,
	GetFavorite: ((option: string) -> boolean)?,
	SetFavorite: ((option: string) -> boolean)?,
	GetOptions: (() -> { string })?,
	Callback: ((selected: string) -> ())?,
}

export type TextInputConfig = {
	Text: string,
	Placeholder: string?,
	Default: string?,
	DependsOn: any?,
	Paid: boolean?,
	PaidBadgeText: string?,
	PaidColor: Color3?,
	PlaceholderClearOnFocus: boolean?,
	Live: boolean?,
	Callback: ((text: string) -> ())?,
}

export type KeybindConfig = {
	Text: string,
	Default: Enum.KeyCode?,
	DependsOn: any?,
	Paid: boolean?,
	PaidBadgeText: string?,
	PaidColor: Color3?,
	Callback: ((key: Enum.KeyCode?) -> ())?,
}

export type NotifyConfig = {
	Title: string,
	Content: string,
	Duration: number?,
	Type: string?,
}

export type CharacterInfo = {
	Client: string?,
	KeyType: string?,
	TimeLeft: string?,
	Executions: number?,
}

export type WindowConfig = {
	Title: string?,
	Name: string?,
	Font: Enum.Font?,
	TextSize: number?,
	KeySystem: boolean?,
	Key: string?,
	KeyLink: string?,
}

export type MultiDropdownConfig = {
	Title: string,
	Options: { string },
	Default: { string }?,
	DependsOn: any?,
	Callback: ((selected: { string }) -> ())?,
}

-- =========================================================================================
--  3. ENGINE - HARDCODED THEME
-- =========================================================================================

local Theme = {
	Colors = {
		Background     = Color3.fromRGB(18, 18, 22),
		Component      = Color3.fromRGB(28, 28, 34),
		ComponentDeep  = Color3.fromRGB(24, 24, 28),
		HoverTint      = Color3.fromRGB(255, 255, 255),
		Text           = Color3.fromRGB(255, 255, 255),
		TextMuted      = Color3.fromRGB(170, 170, 175),
		TextDim        = Color3.fromRGB(112, 112, 120),
		Accent         = Color3.fromRGB(230, 35, 35),
		Card           = Color3.fromRGB(22, 22, 26),
		Stroke         = Color3.fromRGB(44, 44, 52),
		Track          = Color3.fromRGB(40, 40, 48),
		DropdownBar    = Color3.fromRGB(30, 30, 35),
		ModalScrim     = Color3.fromRGB(0, 0, 0),
		Error          = Color3.fromRGB(235, 60, 60),
	},

	Fonts = {
		Logo   = Enum.Font.PermanentMarker,
		Header = Enum.Font.SourceSansBold,
		Body   = Enum.Font.SourceSans,
		Mono   = Enum.Font.SourceSans,
	},

	Sizes = {
		WindowWidth     = 780,
		WindowHeight    = 520,
		HeaderHeight    = 38,
		SidebarWidth    = 176,
		ButtonHeight    = 40,
		ButtonTextSize  = 17,
		Corner          = 8,
		ControlCorner   = 6,
		ControlHeight   = 34,
		CardHeight      = 152,
		CardCorner      = 6,
		AccentBarWidth  = 3,
		AccentBarHeight = 18,
		ContentInset    = 0,
		SidebarInset    = -20,
	},

	Border = {
		Thickness   = 3,
		Period      = 4.0,
		AccentShare = 0.15,
	},

	Anim = {
		Fast   = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Normal = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		Slow   = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		Page   = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},

	Keybind = Enum.KeyCode.RightControl,
}

-- =========================================================================================
--  4. ENGINE - PRIMITIVE BUILDERS
-- =========================================================================================

local function create(className: string, props: {[string]: any}?, children: {Instance}?): any
	local instance = Instance.new(className)
	local parent: Instance? = nil

	if props then
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			else
				(instance :: any)[key] = value
			end
		end
	end

	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function addCorner(parent: Instance, radius: number): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function addPadding(parent: Instance, top: number, right: number, bottom: number, left: number): UIPadding
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		Parent = parent,
	})
end

local function addList(parent: Instance, gap: number, align: Enum.HorizontalAlignment?): UIListLayout
	return create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, gap),
		Parent = parent,
	})
end

local function addStroke(parent: Instance, color: Color3, thickness: number, transparency: number): UIStroke
	return create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- =========================================================================================
--  5. ENGINE - EFFECTS / SHADERS
-- =========================================================================================

local Effects = {}

function Effects.tween(instance: Instance, info: TweenInfo, goal: {[string]: any}): Tween
	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end

function Effects.buildBorderColor(accent: Color3, dark: Color3, share: number): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, accent),
		ColorSequenceKeypoint.new(share * 0.4, accent),
		ColorSequenceKeypoint.new(share, dark),
		ColorSequenceKeypoint.new(1, dark),
	})
end

function Effects.buildBorderTransparency(share: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(share * 0.4, 0),
		NumberSequenceKeypoint.new(share, 0.7),
		NumberSequenceKeypoint.new(1, 0.7),
	})
end

function Effects.rotateBorder(gradient: UIGradient, period: number): Tween
	gradient.Rotation = 0
	local tween = TweenService:Create(
		gradient,
		TweenInfo.new(period, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	)
	tween:Play()
	return tween
end

function Effects.bindHover(row: GuiObject, label: TextLabel?, bar: GuiObject?)
	row.MouseEnter:Connect(function()
		Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 0.9 })
		if label then
			Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
		end
		if bar then
			bar.Visible = true
			Effects.tween(bar, Theme.Anim.Fast, {
				BackgroundTransparency = 0,
				Size = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, Theme.Sizes.AccentBarHeight),
			})
		end
	end)

	row.MouseLeave:Connect(function()
		Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 1 })
		if label then
			Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
		end
		if bar then
			Effects.tween(bar, Theme.Anim.Fast, {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, 0),
			})
		end
	end)
end

-- =========================================================================================
--  5b. DEPENDENCY SYSTEM (DependsOn)
-- =========================================================================================

-- A control may declare DependsOn = <parentControl> (visible while the parent is truthy,
-- e.g. a Toggle that is ON) or DependsOn = { Control = <parentControl>, Value = <expected> }
-- (visible only while the parent's value equals the expected string/number/bool).
local dependencyEntries: { any } = {}

local function _dependsParent(dep: any): any
	if type(dep) ~= "table" then
		return nil
	end
	if dep.Control ~= nil then
		return dep.Control
	end
	if dep.Type ~= nil then
		return dep
	end
	return nil
end

local function _dependsMet(dep: any): boolean
	local parent = _dependsParent(dep)
	if parent == nil then
		return true
	end
	-- direct form: DependsOn = <control object> -> truthy check on its value
	if dep == parent then
		local val = parent.Value
		if typeof(val) == "boolean" then
			return val
		elseif typeof(val) == "string" then
			return val ~= ""
		elseif typeof(val) == "number" then
			return val ~= 0
		end
		return val ~= nil
	end
	local want = dep.Value
	local val = parent.Value
	if want ~= nil then
		return val == want
	end
	if typeof(val) == "boolean" then
		return val
	elseif typeof(val) == "string" then
		return val ~= ""
	elseif typeof(val) == "number" then
		return val ~= 0
	end
	return val ~= nil
end

local function bindDepends(dep: any, frame: Instance)
	local parent = _dependsParent(dep)
	if parent == nil or frame == nil then
		return
	end
	table.insert(dependencyEntries, { parent = parent, frame = frame, dep = dep })
	local met = _dependsMet(dep)
	frame.Visible = met
end

local function refreshDependents(parent: any)
	for _, entry in ipairs(dependencyEntries) do
		if entry.parent == parent then
			local frame = entry.frame
			if frame and frame.Parent then
				local met = _dependsMet(entry.dep)
				if met then
					if not frame.Visible then
						frame.Visible = true
						local scale = frame:FindFirstChild("DepScale")
						if not scale then
							scale = create("UIScale", { Name = "DepScale", Scale = 1, Parent = frame })
						end
						scale.Scale = 0.94
						Effects.tween(scale, Theme.Anim.Normal, { Scale = 1 })
					end
				else
					frame.Visible = false
				end
			end
		end
	end
end

-- Parses a Roblox asset reference from raw digits or a library URL and returns
-- a normalised "rbxassetid://<id>" string (nil when nothing usable is found).
local function parseAssetId(input: string): string?
	if not input or input == "" then
		return nil
	end
	local best = ""
	for run in string.gmatch(input, "%d+") do
		if #run > #best then
			best = run
		end
	end
	if #best < 5 then
		return nil
	end
	return "rbxassetid://" .. best
end

-- Renders a small paid/premium badge immediately after a control's title text.
local function addPaidBadge(label: TextLabel, config: any)
	if not config or not config.Paid then
		return nil
	end
	local color = config.PaidColor or Theme.Colors.Accent
	local badge = create("Frame", {
		Name = "PaidBadge",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 15),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = label,
	})
	addCorner(badge, 4)
	addPadding(badge, 0, 5, 0, 5)
	create("TextLabel", {
		Name = "BadgeText",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Header,
		Text = config.PaidBadgeText or "PRO",
		TextSize = 10,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = badge,
	})
	local function reposition()
		badge.Position = UDim2.new(0, math.max(label.TextBounds.X, 0) + 8, 0.5, 0)
	end
	reposition()
	label:GetPropertyChangedSignal("TextBounds"):Connect(reposition)
	return badge
end

-- =========================================================================================
--  6. GLOBAL KEY-CAPTURE BUS
-- =========================================================================================

local activeKeyCapture: ((Enum.KeyCode) -> ())? = nil

local openDropdowns: { any } = {}
local currentOpenDropdown: any = nil

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	-- keybind capture MUST run before the gameProcessed guard: Roblox flags
	-- KeyCode.I / KeyCode.O (camera zoom) as gameProcessed, which would drop them.
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local capture = activeKeyCapture
		if capture then
			activeKeyCapture = nil
			capture(input.KeyCode)
			return
		end
	end
	if gameProcessed then
		return
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	for _, dropdown in ipairs(openDropdowns) do
		if dropdown.IsOpen and dropdown:IsOpen() then
			local root = dropdown.Root
			local pos = input.Position
			local topLeft = root.AbsolutePosition
			local size = root.AbsoluteSize
			local inside = pos.X >= topLeft.X and pos.X <= topLeft.X + size.X
				and pos.Y >= topLeft.Y and pos.Y <= topLeft.Y + size.Y
			if not inside then
				dropdown:Close()
			end
		end
	end
end)

-- =========================================================================================
--  7. CLASS TABLES
-- =========================================================================================

local Library: any = {}
Library.__index = Library

local Window: any = {}
Window.__index = Window

local Tab: any = {}
Tab.__index = Tab

-- =========================================================================================
--  8. LIBRARY
-- =========================================================================================

local function resolveGuiParent(): Instance
	if LocalPlayer then
		local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			return playerGui
		end
	end
	-- executor-safe: never touch the protected CoreGui service.
	-- gethui() is the executor's safe GUI container when available.
	local hui = nil
	pcall(function()
		hui = gethui and gethui() or nil
	end)
	if hui then
		return hui
	end
	return game:GetService("Players")
end

function Library.new()
	local self = setmetatable({}, Library)

	self.Version = "1.0.0"
	self.Theme = Theme
	self.Windows = {}
	self.ToggleKeybind = Theme.Keybind
	self._notifyOrder = 0
	self._notifications = {}
	self._activeToasts = {}
	self.Acrylic = false
	self._connections = {}
	self.MinimizeIcon = "rbxassetid://6031075931"
	self.MinimizeWidgets = {}
	self._themeBindings = {}
	self.ActiveTheme = "Monochromatic"
	self.CustomBackground = nil
	self.SavedBackgrounds = {}
	self.BackgroundAcrylic = false
	self.AccentTheme = nil
	self.FavoriteThemes = {}

	self.ScreenGui = create("ScreenGui", {
		Name = "SakkaUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		Parent = resolveGuiParent(),
	})

	-- notifications live in their own always-on ScreenGui so toasts stay visible
	-- even while the main menu is hidden via the toggle keybind
	self.NotificationGui = create("ScreenGui", {
		Name = "SakkaUINotifications",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 101,
		Parent = resolveGuiParent(),
	})

	self.NotificationHolder = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, 180, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.NotificationGui,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		Parent = self.NotificationHolder,
	})

	self:_bindToggleKeybind()

	self:SetTheme(self.ActiveTheme)

	return self
end

function Library:_track(connection: RBXScriptConnection)
	table.insert(self._connections, connection)
	return connection
end

function Library:_bindToggleKeybind()
	self:_track(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.KeyCode == self.ToggleKeybind then
			self:Toggle()
		end
	end))
end

-- =========================================================================================
--  THEME ENGINE
-- =========================================================================================

local function themePalette(accent: Color3, background: Color3, card: Color3, text: Color3, textMuted: Color3, backgroundImage: string?)
	return {
		Accent = accent,
		AccentDark = accent:Lerp(Color3.fromRGB(0, 0, 0), 0.4),
		Background = background,
		Card = card,
		CardDeep = card:Lerp(Color3.fromRGB(0, 0, 0), 0.15),
		Text = text,
		TextMuted = textMuted,
		BackgroundImage = backgroundImage,
	}
end

-- ===== 1-WORD PURE ACCENT THEMES (no background artwork) =====
Library.Themes = {
	["Monochromatic"] = themePalette(
		Color3.fromRGB(220, 220, 225),
		Color3.fromRGB(16, 16, 18),
		Color3.fromRGB(26, 26, 30),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(170, 170, 175)
	),
	["Crimson"] = themePalette(
		Color3.fromRGB(230, 35, 35),
		Color3.fromRGB(18, 18, 22),
		Color3.fromRGB(28, 28, 34),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(170, 170, 175)
	),
	["Sapphire"] = themePalette(
		Color3.fromRGB(30, 144, 255),
		Color3.fromRGB(12, 18, 28),
		Color3.fromRGB(20, 28, 42),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(165, 185, 210)
	),
	["Midnight"] = themePalette(
		Color3.fromRGB(35, 35, 45),
		Color3.fromRGB(10, 10, 14),
		Color3.fromRGB(20, 20, 26),
		Color3.fromRGB(240, 240, 245),
		Color3.fromRGB(140, 145, 160)
	),
	["Sunset"] = themePalette(
		Color3.fromRGB(255, 120, 30),
		Color3.fromRGB(22, 16, 12),
		Color3.fromRGB(34, 26, 20),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(200, 180, 165)
	),
	["Emerald"] = themePalette(
		Color3.fromRGB(35, 200, 100),
		Color3.fromRGB(14, 22, 18),
		Color3.fromRGB(24, 34, 28),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(165, 190, 175)
	),
	["Purple"] = themePalette(
		Color3.fromRGB(140, 35, 230),
		Color3.fromRGB(20, 14, 28),
		Color3.fromRGB(30, 24, 40),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(180, 165, 200)
	),
	["Sakura"] = themePalette(
		Color3.fromRGB(255, 80, 170),
		Color3.fromRGB(18, 8, 16),
		Color3.fromRGB(30, 16, 26),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(205, 165, 190)
	),
	-- ===== 2-WORD PREMIUM PRESET THEMES (literal names matching the artwork) =====
	["Midnight Storm"] = themePalette(
		Color3.fromRGB(35, 35, 45),
		Color3.fromRGB(10, 10, 14),
		Color3.fromRGB(20, 20, 26),
		Color3.fromRGB(240, 240, 245),
		Color3.fromRGB(140, 145, 160),
		"rbxassetid://110398670941669"
	),
	["Crimson Blossom"] = themePalette(
		Color3.fromRGB(220, 40, 40),
		Color3.fromRGB(18, 18, 22),
		Color3.fromRGB(28, 28, 34),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(170, 170, 175),
		"rbxassetid://134133843123985"
	),
	["Sapphire Blade"] = themePalette(
		Color3.fromRGB(0, 162, 255),
		Color3.fromRGB(12, 18, 28),
		Color3.fromRGB(20, 28, 42),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(165, 185, 210),
		"rbxassetid://107490384408166"
	),
	["Purple Cat"] = themePalette(
		Color3.fromRGB(160, 32, 240),
		Color3.fromRGB(20, 14, 28),
		Color3.fromRGB(30, 24, 40),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(180, 165, 200),
		"rbxassetid://114186349768027"
	),
	["Sakura Cat"] = themePalette(
		Color3.fromRGB(255, 105, 180),
		Color3.fromRGB(18, 8, 16),
		Color3.fromRGB(30, 16, 26),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(205, 165, 190),
		"rbxassetid://113345544081903"
	),
}

function Library:RegisterTheme(themeName: string, colors: {[string]: Color3})
	local base = Library.Themes["Crimson Eclipse"]
	local merged: any = {}
	for key, value in pairs(base) do
		merged[key] = value
	end
	for key, value in pairs(colors) do
		merged[key] = value
	end
	Library.Themes[themeName] = merged
end

function Library:_bind(instance: any, property: string, token: string)
	table.insert(self._themeBindings, { instance = instance, property = property, token = token })
end

function Library:SetTheme(themeName: string)
	local palette = Library.Themes[themeName]
	if not palette then
		return
	end

	self.ActiveTheme = themeName
	self.CustomBackground = nil
	for _, window in ipairs(self.Windows) do
		window.CustomBackground = nil
	end

	for key, value in pairs(palette) do
		(Theme.Colors :: any)[key] = value
	end

	for _, binding in ipairs(self._themeBindings) do
		local instance = binding.instance
		if instance and instance.Parent then
			local value = palette[binding.token]
			if value then
				pcall(function()
					(instance :: any)[binding.property] = value
				end)
			end
		end
	end

	for _, window in ipairs(self.Windows) do
		if window._refreshTheme then
			window:_refreshTheme(palette)
		end
	end
end

-- Applies a custom background artwork to every window; nil/"" resets to the active theme's art.
function Library:SetBackgroundImage(assetId: string?)
	self.CustomBackground = assetId
	for _, window in ipairs(self.Windows) do
		window.CustomBackground = (assetId and assetId ~= "") and assetId or nil
		window:_setBackgroundImage(assetId)
	end
end

function Library:SetAccent(themeName: string)
	local palette = Library.Themes[themeName]
	if not palette then
		return
	end
	self.AccentTheme = themeName
	local base = Library.Themes[self.ActiveTheme] or Library.Themes["Crimson Eclipse"]
	local merged: any = {}
	for key, value in pairs(base) do
		merged[key] = value
	end
	merged.Accent = palette.Accent
	merged.AccentDark = palette.AccentDark
	merged.BackgroundImage = nil
	for key, value in pairs(merged) do
		(Theme.Colors :: any)[key] = value
	end
	for _, window in ipairs(self.Windows) do
		if window._refreshTheme then
			window:_refreshTheme(merged)
		end
	end
end

function Library:SetBackgroundAcrylic(value: number)
	local amount = math.clamp(value or 0, 0, 100)
	self.BackgroundAcrylic = amount
	local transparency = amount / 100
	for _, window in ipairs(self.Windows) do
		local img = window.BackgroundImage
		if img then
			Effects.tween(img, Theme.Anim.Normal, { ImageTransparency = transparency })
		end
	end
end

-- Hard-clears any background override (no fallback to the active theme artwork).
function Library:ClearBackground()
	self.CustomBackground = nil
	for _, window in ipairs(self.Windows) do
		window.CustomBackground = nil
		if window.BackgroundImage then
			window.BackgroundImage.Image = ""
			window.BackgroundImage.Visible = false
		end
	end
end

function Library:_backgroundStore(): string?
	if not writefile then
		return nil
	end
	local folder = self:_configFolder()
	if not folder then
		return nil
	end
	return folder .. "/backgrounds.json"
end

function Library:SaveBackground(name: string, assetId: string)
	if not assetId or assetId == "" then
		return false
	end
	if not name or name == "" then
		name = assetId
	end
	self.SavedBackgrounds = self.SavedBackgrounds or {}
	self.SavedBackgrounds[name] = assetId
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(self.SavedBackgrounds)
	end)
	if ok then
		local path = self:_backgroundStore()
		if path then
			pcall(function()
				writefile(path, encoded)
			end)
		end
	end
	return true
end

function Library:GetSavedBackgrounds(): { string }
	self.SavedBackgrounds = self.SavedBackgrounds or {}
	local path = self:_backgroundStore()
	if path and readfile and isfile then
		local ok, data = pcall(function()
			if isfile(path) then
				return readfile(path)
			end
			return nil
		end)
		if ok and type(data) == "string" then
			local ok2, decoded = pcall(function()
				return HttpService:JSONDecode(data)
			end)
			if ok2 and type(decoded) == "table" then
				self.SavedBackgrounds = decoded
			end
		end
	end
	local names = {}
	for name in pairs(self.SavedBackgrounds) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Library:GetBackgroundAsset(name: string): string?
	self.SavedBackgrounds = self.SavedBackgrounds or {}
	return self.SavedBackgrounds[name]
end

function Library:SetAcrylic(enabled: boolean)
	self.Acrylic = enabled
	for _, window in ipairs(self.Windows) do
		if window.Main then
			Effects.tween(window.Main, Theme.Anim.Normal, {
				BackgroundTransparency = enabled and 0.35 or 0,
			})
		end
		if window.Card then
			Effects.tween(window.Card, Theme.Anim.Normal, {
				BackgroundTransparency = enabled and 0.45 or 0,
			})
		end
		if window._applyAcrylic then
			window:_applyAcrylic(enabled)
		end
	end

	-- keep live notification toasts in sync with the acrylic state
	if self.NotificationHolder then
		for _, toast in ipairs(self.NotificationHolder:GetChildren()) do
			local card = toast:FindFirstChild("Card")
			if card and card:IsA("GuiObject") then
				Effects.tween(card, Theme.Anim.Normal, { BackgroundTransparency = enabled and 0.35 or 0 })
			end
		end
	end
end

local function safeCall(fn: () -> any): (boolean, any)
	if type(fn) ~= "function" then
		return false, nil
	end
	return pcall(fn)
end

function Library:_configFolder(): string?
	if not writefile then
		return nil
	end
	local root = "SakkaUI"
	local configs = root .. "/Configs"
	local ok = safeCall(function()
		if not isfolder(root) then
			makefolder(root)
		end
		if not isfolder(configs) then
			makefolder(configs)
		end
	end)
	if not ok then
		return nil
	end
	return configs
end

function Library:ListConfigs(): { string }
	self._memConfigs = self._memConfigs or {}
	local folder = self:_configFolder()
	local names = {}

	if folder and listfiles then
		local ok, files = pcall(function()
			return listfiles(folder)
		end)
		if ok and type(files) == "table" then
			for _, path in ipairs(files) do
				local name = string.match(path, "([^/\\]+)%.json$")
				if name then
					table.insert(names, name)
				end
			end
			return names
		end
	end

	for name in pairs(self._memConfigs) do
		table.insert(names, name)
	end
	return names
end

function Library:SaveConfig(configName: string)
	self._memConfigs = self._memConfigs or {}

	local payload: any = {
		Theme = self.ActiveTheme,
		Acrylic = self.Acrylic == true,
		Flags = {},
	}

	for _, window in ipairs(self.Windows) do
		for _, tab in pairs(window.Tabs) do
			for flagName, object in pairs(tab.Flags) do
				local value = object.Value
				if typeof(value) == "EnumItem" then
					value = tostring(value)
				elseif typeof(value) == "table" then
					value = table.concat(value, ",")
				end
				payload.Flags[flagName] = value
			end
		end
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		return false
	end

	local folder = self:_configFolder()
	if folder and writefile then
		local wrote = pcall(function()
			writefile(folder .. "/" .. configName .. ".json", encoded)
		end)
		if wrote then
			return true
		end
	end

	self._memConfigs[configName] = encoded
	return true
end

function Library:LoadConfig(configName: string)
	self._memConfigs = self._memConfigs or {}
	local encoded: string? = nil

	local folder = self:_configFolder()
	if folder and readfile and isfile then
		local ok, data = pcall(function()
			local path = folder .. "/" .. configName .. ".json"
			if isfile(path) then
				return readfile(path)
			end
			return nil
		end)
		if ok and type(data) == "string" then
			encoded = data
		end
	end

	if not encoded then
		encoded = self._memConfigs[configName]
	end
	if not encoded then
		return false
	end

	local ok, payload = pcall(function()
		return HttpService:JSONDecode(encoded)
	end)
	if not ok or type(payload) ~= "table" then
		return false
	end

	if payload.Theme then
		self:SetTheme(payload.Theme)
	end
	if payload.Acrylic ~= nil then
		self:SetAcrylic(payload.Acrylic == true)
	end

	local flags = payload.Flags or {}
	for _, window in ipairs(self.Windows) do
		for _, tab in pairs(window.Tabs) do
			for flagName, object in pairs(tab.Flags) do
				local raw = flags[flagName]
				if raw ~= nil then
					if object.Type == "Keybind" then
						local key = Enum.KeyCode[raw]
						if key then
							object:Set(key, true)
						end
					elseif object.Type == "MultiDropdown" then
						local list = {}
						for item in string.gmatch(raw, "([^,]+)") do
							table.insert(list, item)
						end
						object:Set(list, true)
					elseif object.Set then
						object:Set(raw, true)
					end
				end
			end
		end
	end

	return true
end

function Library:GetThemes(): { string }
	local names = {}
	for name in pairs(Library.Themes) do
		table.insert(names, name)
	end
	table.sort(names)
	-- favorites pin to the very top (alphabetical within each group)
	local favs = self.FavoriteThemes or {}
	local top, rest = {}, {}
	for _, name in ipairs(names) do
		if favs[name] then
			table.insert(top, name)
		else
			table.insert(rest, name)
		end
	end
	local merged = {}
	for _, name in ipairs(top) do
		table.insert(merged, name)
	end
	for _, name in ipairs(rest) do
		table.insert(merged, name)
	end
	return merged
end

function Library:IsFavoriteTheme(name: string): boolean
	return self.FavoriteThemes ~= nil and self.FavoriteThemes[name] == true
end

function Library:ToggleFavoriteTheme(name: string): boolean
	self.FavoriteThemes = self.FavoriteThemes or {}
	if self.FavoriteThemes[name] then
		self.FavoriteThemes[name] = nil
		return false
	end
	self.FavoriteThemes[name] = true
	return true
end

function Library:SetMinimizeIcon(assetId: string)
	self.MinimizeIcon = assetId
	for _, widget in ipairs(self.MinimizeWidgets) do
		local icon = widget:FindFirstChild("Icon")
		if icon then
			icon.Image = assetId
		end
	end
end

function Library:Unload()
	for _, connection in ipairs(self._connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(self._connections)

	for _, window in ipairs(self.Windows) do
		if window.Destroy then
			pcall(function()
				window:Destroy()
			end)
		end
	end
	table.clear(self.Windows)

	self.MinimizeWidgets = {}

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
	if self.NotificationGui then
		self.NotificationGui:Destroy()
		self.NotificationGui = nil
	end
end

function Library:SetToggleKeybind(key: Enum.KeyCode)
	self.ToggleKeybind = key
end

function Library:Toggle()
	if self.ScreenGui then
		self.ScreenGui.Enabled = not self.ScreenGui.Enabled
	end
	local key = self.ToggleKeybind
	self:Notify({
		Title = "Toggled",
		Content = "Press " .. (key and key.Name or "the keybind") .. " to toggle menu",
		Duration = 3,
	})
end

function Library:CreateWindow(config: WindowConfig?)
	local resolved: WindowConfig = config or {}

	local window = setmetatable({}, Window)
	window.Title = resolved.Title or resolved.Name or "Sakka"
	window.TitleFont = resolved.Font or Theme.Fonts.Logo
	window.TitleSize = resolved.TextSize or 24
	window.Library = self
	window.Tabs = {}
	window.TabOrder = 0
	window.Dragging = false
	window.DragSmoothing = 0.06
	window.IsMinimized = false
	window.ButtonLayout = "Left"
	window.SectionLayout = "Columns"
	window.ScaleMode = "Standard (100%)"

	window:_build(self.ScreenGui)
	window:_bindDrag()

	table.insert(self.Windows, window)

	window:_buildSettings()

	if resolved.KeySystem then
		window:_buildKeySystem(resolved.Key or "", resolved.KeyLink or "")
	end

	return window
end

function Window:_buildSettings()
	local library = self.Library
	local tab = self:CreateTab("Settings")
	tab.Button.LayoutOrder = 1000
	tab:AddSection("Customize")

-- Static, immutable theme registry: the single source of truth for presets.
	-- Restores NEVER read live UI colors - they look the theme up here by name.
	local ThemeRegistry = {}
	if library then
		for name, pal in pairs(library.Themes) do
			ThemeRegistry[name] = { Accent = pal.Accent, Image = pal.BackgroundImage or "" }
		end
	end

	-- PresetState stores ONLY the theme NAME plus acrylic flag (no captured colors)
	local PresetState = {
		ThemeName = library and library.ActiveTheme or "Singularity Void",
		GUIAcrylic = false,
	}
	local CustomState = {
		ColorTheme = "Monochromatic",
		CustomBackgroundId = "",
		SavedBackgrounds = {},
		BackgroundAcrylicValue = 0,
		GUIAcrylic = false,
	}
	local customActive = false
	local preCustomAcrylicState = false

	local function enforceCustomBackground()
		if not library then
			return
		end
		if CustomState.CustomBackgroundId ~= "" then
			library:SetBackgroundImage(CustomState.CustomBackgroundId)
		else
			library:ClearBackground()
		end
	end

	local function applyCustomState()
		if not library then
			return
		end
		library:SetAccent(CustomState.ColorTheme)
		enforceCustomBackground()
		library:SetBackgroundAcrylic(CustomState.BackgroundAcrylicValue)
		library:SetAcrylic(CustomState.GUIAcrylic)
	end

	local function applyPresetState()
		if not library then
			return
		end
		local data = ThemeRegistry[PresetState.ThemeName]
		-- atomic restore straight from the static registry
		library:SetTheme(PresetState.ThemeName)
		if data and data.Accent then
			library:SetAccent(PresetState.ThemeName)
		end
		if data and data.Image ~= "" then
			library:SetBackgroundImage(data.Image)
		else
			library:ClearBackground()
		end
		library:SetBackgroundAcrylic(0)
		library:SetAcrylic(PresetState.GUIAcrylic == true)
	end

-- 1. Preset Theme dropdown (owned by PresetState; only updates while NOT in Custom)
	local themeDropdown
	themeDropdown = tab:AddDropdown({
		Text = "Theme",
		Options = library and library:GetThemes() or { "Monochromatic" },
		Default = library and library.ActiveTheme or "Monochromatic",
		Favorites = true,
		GetFavorite = function(option: string)
			return library and library:IsFavoriteTheme(option) or false
		end,
		SetFavorite = function(option: string)
			if library then
				library:ToggleFavoriteTheme(option)
			end
		end,
		GetOptions = function()
			return library and library:GetThemes() or {}
		end,
		Callback = function(selected: string)
			if not library or customActive then
				return
			end
			library:SetTheme(selected)
			-- PresetState is ONLY written here, while Custom is off - and only the NAME
			PresetState.ThemeName = selected
		end,
	})

-- 2. GUI Acrylic toggle (preset-side; tracked in PresetState)
	local acrylicToggle
	acrylicToggle = tab:AddToggle({
		Text = "Acrylic",
		Default = false,
		Callback = function(state: boolean)
			PresetState.GUIAcrylic = state
			if library then
				library:SetAcrylic(state)
			end
		end,
	})

-- 3. Custom master toggle (strict transitions, no snapshotting)

	local customToggle
	customToggle = tab:AddToggle({
		Text = "Custom",
		Default = false,
		Callback = function(state: boolean)
			if not library then
				return
			end
			if state == customActive then
				return
			end
			customActive = state
			if state then
				-- cache + lock the main Acrylic toggle
				preCustomAcrylicState = acrylicToggle:Get()
				acrylicToggle:SetInteractable(false)
				applyCustomState()
			else
				applyPresetState()
				acrylicToggle:SetInteractable(true)
				acrylicToggle:Set(preCustomAcrylicState == true, true)
				if PresetState.ThemeName then
					themeDropdown:Set(PresetState.ThemeName, false)
				end
			end
			themeDropdown:SetInteractable(not state)
		end,
	})

-- 3. Custom dependent children (in strict order)
	tab:AddDropdown({
		Text = "Color Theme",
		Options = { "Monochromatic", "Crimson", "Sapphire", "Midnight", "Sunset", "Emerald", "Purple", "Sakura" },
		Default = "Monochromatic",
		DependsOn = customToggle,
		Callback = function(selected: string)
			CustomState.ColorTheme = selected
			if library then
				-- accent palette ONLY; never read a preset background id
				library:SetAccent(selected)
				enforceCustomBackground()
			end
		end,
	})

	tab:AddTextInput({
		Text = "Custom Background",
		Placeholder = "rbxassetid://80372737522626",
		PlaceholderClearOnFocus = true,
		Live = true,
		DependsOn = customToggle,
		Callback = function(value: string)
			local id = parseAssetId(value)
			if id then
				CustomState.CustomBackgroundId = id
				if library then
					library:SetBackgroundImage(id)
				end
			end
		end,
	})

	local savedDropdown
	savedDropdown = tab:AddDropdown({
		Text = "Saved Backgrounds",
		Options = { "(none)" },
		Default = "(none)",
		DependsOn = customToggle,
		Callback = function(selected: string)
			if selected ~= "(none)" and library then
				local assetId = library:GetBackgroundAsset(selected) or selected
				CustomState.CustomBackgroundId = assetId
				library:SetBackgroundImage(assetId)
			end
		end,
	})

	local nameInput
	nameInput = tab:AddTextInput({
		Text = "Background Name",
		Placeholder = "My Dark Space",
		PlaceholderClearOnFocus = true,
		DependsOn = customToggle,
		Callback = function() end,
	})

	tab:AddButton({
		Text = "Save Background",
		DependsOn = customToggle,
		Callback = function()
			if not library or CustomState.CustomBackgroundId == "" then
				if library then
					library:Notify({ Title = "Backgrounds", Content = "No background to save.", Duration = 3 })
				end
				return
			end
			local name = nameInput and nameInput:Get() or ""
			if name == "" then
				name = CustomState.CustomBackgroundId
			end
			library:SaveBackground(name, CustomState.CustomBackgroundId)
			CustomState.SavedBackgrounds[name] = CustomState.CustomBackgroundId
			local list = library:GetSavedBackgrounds()
			if savedDropdown and #list > 0 then
				savedDropdown:Refresh(list)
			end
			if nameInput then
				nameInput:Set("", false)
			end
			library:Notify({ Title = "Backgrounds", Content = "Saved background '" .. name .. "'!", Duration = 3 })
		end,
	})

	local guiAcrylicToggle
	guiAcrylicToggle = tab:AddToggle({
		Text = "GUI Acrylic",
		Default = false,
		DependsOn = customToggle,
		Callback = function(state: boolean)
			CustomState.GUIAcrylic = state
			if library then
				library:SetAcrylic(state)
				-- background acrylic only applies while GUI acrylic is on
				if state then
					library:SetBackgroundAcrylic(CustomState.BackgroundAcrylicValue)
				else
					library:SetBackgroundAcrylic(0)
				end
			end
		end,
	})

	tab:AddSlider({
		Text = "Background Acrylic",
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = "%",
		DependsOn = guiAcrylicToggle,
		Callback = function(value: number)
			CustomState.BackgroundAcrylicValue = value
			if library then
				library:SetBackgroundAcrylic(value)
			end
		end,
	})

	if library then
		local list = library:GetSavedBackgrounds()
		if savedDropdown and #list > 0 then
			savedDropdown:Refresh(list)
		end
	end

-- 5. Remaining general controls
	tab:AddDropdown({
		Text = "Button Layout",
		Options = { "Left", "Top", "Bottom", "Right" },
		Default = "Left",
		Callback = function(selected: string)
			self:SetButtonLayout(selected)
		end,
	})
	tab:AddDropdown({
		Text = "Section Layout",
		Options = { "Columns", "Stacked" },
		Default = "Columns",
		Callback = function(selected: string)
			self:SetSectionLayout(selected)
		end,
	})
	tab:AddKeybind({
		Text = "Menu Toggle",
		Default = library and library.ToggleKeybind or Enum.KeyCode.RightControl,
		Callback = function(key: Enum.KeyCode?)
			if library and key then
				library:SetToggleKeybind(key)
			end
		end,
	})
	tab:AddDropdown({
		Text = "UI Scale",
		Options = { "Compact (85%)", "Standard (100%)", "Large (115%)", "Custom (Freeform)" },
		Default = "Standard (100%)",
		Callback = function(selected: string)
			self:SetScaleMode(selected)
		end,
	})
	tab:AddSlider({
		Text = "Corner Rounding",
		Min = 0,
		Max = 20,
		Default = 8,
		Suffix = "px",
		Callback = function(value: number)
			self:SetCornerRadius(math.round(value))
		end,
	})
	tab:AddSection("Configs")
	local nameBox = tab:AddTextInput({
		Text = "Config Name",
		Placeholder = "my_config",
		Callback = function() end,
	})
	tab:AddButton({
		Text = "Save Config",
		Callback = function()
			local name = nameBox:Get()
			if name == "" then
				name = "default"
			end
			if library then
				local ok = library:SaveConfig(name)
				library:Notify({
					Title = "Configs",
					Content = ok and ("Saved '" .. name .. "'.") or "Save failed.",
					Duration = 3,
				})
			end
		end,
	})
	tab:AddButton({
		Text = "Load Config",
		Callback = function()
			local name = nameBox:Get()
			if library then
				local ok = library:LoadConfig(name)
				library:Notify({
					Title = "Configs",
					Content = ok and ("Loaded '" .. name .. "'.") or "Config not found.",
					Duration = 3,
				})
			end
		end,
	})
	tab:AddDropdown({
		Text = "Saved Configs",
		Options = (library and #library:ListConfigs() > 0) and library:ListConfigs() or { "(none)" },
		Default = "(none)",
		Callback = function(selected: string)
			if selected ~= "(none)" then
				nameBox:Set(selected, false)
			end
		end,
	})
	return tab
end

function Window:_applyAcrylic(enabled: boolean)
	local value = enabled and 0.45 or 0
	if self.Body then
		for _, page in ipairs(self.Body.Content:GetChildren()) do
			if page:IsA("ScrollingFrame") then
				local layer = page:FindFirstChild("TransitionLayer")
				local columns = layer and layer:FindFirstChild("Columns")
				if columns then
					for _, col in ipairs(columns:GetChildren()) do
						if col:IsA("Frame") then
							for _, section in ipairs(col:GetChildren()) do
								if section:IsA("Frame") and section:FindFirstChild("Heading") then
									section.BackgroundColor3 = Theme.Colors.Card
									Effects.tween(section, Theme.Anim.Normal, { BackgroundTransparency = value })
								end
							end
						end
					end
				end
			end
		end
	end
end

function Window:_setBackgroundImage(assetId: string?)
	if not self.BackgroundImage then
		return
	end
	local resolved = assetId
	if resolved == nil or resolved == "" then
		resolved = Theme.Colors.BackgroundImage
	end
	if resolved then
		self.BackgroundImage.Image = resolved
		self.BackgroundImage.Visible = true
	else
		self.BackgroundImage.Visible = false
	end
	local lib = self.Library
	if lib and lib.BackgroundAcrylic then
		self.BackgroundImage.ImageTransparency = math.clamp(lib.BackgroundAcrylic, 0, 100) / 100
	end
end

function Window:_refreshTheme(palette: any)
	if self.BackgroundImage then
		local img = self.CustomBackground or palette.BackgroundImage
		if img then
			self.BackgroundImage.Image = img
			self.BackgroundImage.Visible = true
		else
			self.BackgroundImage.Visible = false
		end
	end
	if self.Main then
		self.Main.BackgroundColor3 = palette.Background
	end

	if self.TitleLabel then
		self.TitleLabel.TextColor3 = palette.Accent
	end

	if self.BorderGradient then
		self.BorderGradient.Color = Effects.buildBorderColor(
			palette.Accent,
			Theme.Colors.Stroke,
			Theme.Border.AccentShare
		)
	end

	if self.Card then
		self.Card.BackgroundColor3 = palette.CardDeep
	end

	if self.BackgroundImage then
		if palette.BackgroundImage then
			self.BackgroundImage.Image = palette.BackgroundImage
			self.BackgroundImage.Visible = true
		else
			self.BackgroundImage.Visible = false
		end
	end

	if not self.Main then
		return
	end

	-- walk the whole tree and recolor by role
	local function walk(inst: Instance)
		for _, child in ipairs(inst:GetChildren()) do
			if child:IsA("GuiObject") then
				if child.Name == "Accent" then
					child.BackgroundColor3 = palette.Accent
				elseif child.Name == "HeaderDivider" or child.Name == "SidebarDivider" then
					child.BackgroundColor3 = palette.Accent
				elseif child.Name == "Heading" and child:IsA("TextLabel") then
					child.TextColor3 = palette.Accent
				elseif child.Name == "Selected" and child:IsA("TextLabel") then
					child.TextColor3 = palette.Accent
				elseif child.Name == "FavStar" and child:IsA("TextButton") then
					child.TextColor3 = child:GetAttribute("Favorited") and palette.Accent or Color3.fromRGB(130, 130, 130)
				elseif child.Name == "Card" and child:IsA("GuiObject") then
					child.BackgroundColor3 = palette.Card
				elseif child.Name == "Avatar" and child:IsA("ImageLabel") then
					child.BackgroundColor3 = palette.Card
				elseif string.sub(child.Name, 1, 8) == "Section_" and child:IsA("Frame") then
					child.BackgroundColor3 = palette.Card
				end
			end
			walk(child)
		end
	end

	walk(self.Main)

	-- state-aware recolor of active interactive controls
	for _, tab in pairs(self.Tabs) do
		for _, object in pairs(tab.Flags) do
			local inst = object.Instance
			if inst and inst.Parent then
				if object.Type == "Toggle" then
					local switch = inst:FindFirstChild("Switch")
					local knob = switch and switch:FindFirstChild("Knob")
					if switch then
						if object.Value then
							switch.BackgroundColor3 = palette.Accent
							if knob then
								knob.BackgroundColor3 = palette.Text
							end
						else
							switch.BackgroundColor3 = Theme.Colors.Track
							if knob then
								knob.BackgroundColor3 = Theme.Colors.TextMuted
							end
						end
					end
				elseif object.Type == "Slider" then
					local fill = inst:FindFirstChild("Fill", true)
					local knob = inst:FindFirstChild("Knob", true)
					if fill and fill:IsA("Frame") then
						fill.BackgroundColor3 = palette.Accent
					end
					if knob and knob:IsA("Frame") then
						knob.BackgroundColor3 = palette.Accent
					end
				elseif object.Type == "Keybind" then
					local keyBtn = inst:FindFirstChild("Key")
					if keyBtn and keyBtn:IsA("TextButton") then
						if object.Value then
							keyBtn.TextColor3 = palette.Accent
						else
							keyBtn.TextColor3 = Theme.Colors.TextDim
						end
					end
				end
			end
		end
	end

	-- keep section transparency consistent with the current acrylic state
	local library = self.Library
	if library and library.Acrylic and self._applyAcrylic then
		self:_applyAcrylic(true)
	end
end

-- =========================================================================================
--  9. WINDOW
-- =========================================================================================

function Window:_build(parent: Instance)
	local main = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(Theme.Sizes.WindowWidth, Theme.Sizes.WindowHeight),
		BackgroundColor3 = Theme.Colors.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = parent,
	})
	addCorner(main, Theme.Sizes.Corner)
	self.Main = main
	-- cache the startup size so preset scale modes can restore it exactly
	self.InitialWindowSize = main.Size

	-- optional premium background image layer
	local bgImage = create("ImageLabel", {
		Name = "BackgroundImage",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
		ZIndex = 1,
		Parent = main,
	})
	addCorner(bgImage, Theme.Sizes.Corner)
	self.BackgroundImage = bgImage

	-- animated 4-second rotating neon border
	local stroke = addStroke(main, Color3.fromRGB(255, 255, 255), Theme.Border.Thickness, 0)
	self.Stroke = stroke

	local gradient = create("UIGradient", {
		Color = Effects.buildBorderColor(Theme.Colors.Accent, Theme.Colors.Stroke, Theme.Border.AccentShare),
		Transparency = Effects.buildBorderTransparency(Theme.Border.AccentShare),
		Rotation = 0,
		Parent = stroke,
	})
	self.BorderGradient = gradient
	self.BorderTween = Effects.rotateBorder(gradient, Theme.Border.Period)

	-- header
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Theme.Sizes.HeaderHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main,
	})
	self.Header = header

	create("ImageLabel", {
		Name = "HeaderLogo",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundTransparency = 1,
		Image = STAR_EYE_IMAGE_ID,
		ScaleType = Enum.ScaleType.Fit,
		Parent = header,
	})

	self.TitleLabel = create("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 48, 0.5, 0),
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundTransparency = 1,
		Font = self.TitleFont,
		Text = self.Title,
		TextSize = self.TitleSize,
		TextColor3 = Theme.Colors.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		Parent = header,
	})

	-- top-bar centered search input
	local search = create("TextBox", {
		Name = "SearchBox",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 260, 0, 26),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BorderSizePixel = 0,
		Font = Enum.Font.SourceSans,
		Text = "",
		PlaceholderText = "Search for a function here",
		PlaceholderColor3 = Color3.fromRGB(140, 140, 145),
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextScaled = false,
		ClearTextOnFocus = false,
		Parent = header,
	})
	addCorner(search, 6)
	addStroke(search, Theme.Colors.Stroke, 1, 0.4)
	addPadding(search, 0, 10, 0, 10)
	self.SearchBox = search

	search:GetPropertyChangedSignal("Text"):Connect(function()
		self:_applySearch(search.Text)
	end)

	-- top-right window controls
	local controls = create("Frame", {
		Name = "WindowControls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 24),
		BackgroundTransparency = 1,
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = controls,
	})

	local hoverTint = Color3.fromRGB(255, 255, 255)
	local hoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local minimize = create("TextButton", {
		Name = "Minimize",
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = hoverTint,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Enum.Font.SourceSansBold,
		Text = "-",
		TextSize = 16,
		TextColor3 = Theme.Colors.TextMuted,
		TextScaled = false,
		LayoutOrder = 1,
		Parent = controls,
	})
	addCorner(minimize, 6)

	local close = create("TextButton", {
		Name = "Close",
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = hoverTint,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Enum.Font.SourceSansBold,
		Text = "X",
		TextSize = 14,
		TextColor3 = Theme.Colors.TextMuted,
		TextScaled = false,
		LayoutOrder = 2,
		Parent = controls,
	})
	addCorner(close, 6)

	self.MinimizeButton = minimize
	self.CloseButton = close

	local function bindHover(button: TextButton)
		button.MouseEnter:Connect(function()
			Effects.tween(button, hoverInfo, { BackgroundTransparency = 0.92 })
			Effects.tween(button, hoverInfo, { TextColor3 = Theme.Colors.Text })
		end)
		button.MouseLeave:Connect(function()
			Effects.tween(button, hoverInfo, { BackgroundTransparency = 1 })
			Effects.tween(button, hoverInfo, { TextColor3 = Theme.Colors.TextMuted })
		end)
	end

	bindHover(minimize)
	bindHover(close)

	-- 1px red header divider
	self.HeaderDivider = create("Frame", {
		Name = "HeaderDivider",
		Position = UDim2.new(0, 0, 0, Theme.Sizes.HeaderHeight),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Colors.Accent,
		BorderSizePixel = 0,
		Parent = main,
	})

	-- body
	local body = create("Frame", {
		Name = "Body",
		Position = UDim2.new(0, 0, 0, Theme.Sizes.HeaderHeight + 1),
		Size = UDim2.new(1, 0, 1, -(Theme.Sizes.HeaderHeight + 1)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main,
	})

	local sidebar = create("ScrollingFrame", {
		Name = "Sidebar",
		Size = UDim2.new(0, Theme.Sizes.SidebarWidth, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = body,
	})
	addPadding(sidebar, 10, 10, 10, 10)
	addList(sidebar, 6)
	self.Sidebar = sidebar

	self.SidebarDivider = create("Frame", {
		Name = "SidebarDivider",
		Position = UDim2.new(0, Theme.Sizes.SidebarWidth, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Colors.Accent,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Parent = body,
	})

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, Theme.Sizes.SidebarWidth + 1, 0, 0),
		Size = UDim2.new(1, -(Theme.Sizes.SidebarWidth + 1), 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = body,
	})
	self.Content = content
	self.Body = body

	-- nav list layout reference (used by SetButtonLayout)
	self.SidebarLayout = sidebar:FindFirstChildOfClass("UIListLayout")

	self.MinimizeButton.MouseButton1Click:Connect(function()
		self:Minimize()
	end)

	self.CloseButton.MouseButton1Click:Connect(function()
		self:_buildUnloadModal()
	end)
end

function Window:SetButtonLayout(layout: string)
	local sidebar = self.Sidebar
	local divider = self.SidebarDivider
	local content = self.Content
	if not sidebar or not divider or not content then
		return
	end

	self.ButtonLayout = layout

	local layoutObj = sidebar:FindFirstChildOfClass("UIListLayout")
	local pad = sidebar:FindFirstChildOfClass("UIPadding")
	local sidebarW = Theme.Sizes.SidebarWidth
	local barH = Theme.Sizes.ButtonHeight + 22
	local horizontal = (layout == "Top" or layout == "Bottom")

	if layoutObj then
		layoutObj.FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
		layoutObj.VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top
		layoutObj.HorizontalAlignment = horizontal and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center
	end

	if pad then
		if horizontal then
			pad.PaddingTop = UDim.new(0, 6)
			pad.PaddingBottom = UDim.new(0, 6)
			pad.PaddingLeft = UDim.new(0, 8)
			pad.PaddingRight = UDim.new(0, 8)
		else
			pad.PaddingTop = UDim.new(0, 10)
			pad.PaddingBottom = UDim.new(0, 10)
			pad.PaddingLeft = UDim.new(0, 10)
			pad.PaddingRight = UDim.new(0, 10)
		end
	end

	if horizontal then
		sidebar.ScrollingDirection = Enum.ScrollingDirection.X
		sidebar.AutomaticCanvasSize = Enum.AutomaticSize.X
		sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	else
		sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
		sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
		sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	end

	if layout == "Top" then
		sidebar.Position = UDim2.new(0, 0, 0, 0)
		sidebar.Size = UDim2.new(1, 0, 0, barH)
		divider.Position = UDim2.new(0, 0, 0, barH)
		divider.Size = UDim2.new(1, 0, 0, 1)
		content.Position = UDim2.new(0, 0, 0, barH + 1)
		content.Size = UDim2.new(1, 0, 1, -(barH + 1))
	elseif layout == "Bottom" then
		sidebar.Position = UDim2.new(0, 0, 1, -barH)
		sidebar.Size = UDim2.new(1, 0, 0, barH)
		divider.Position = UDim2.new(0, 0, 1, -(barH + 1))
		divider.Size = UDim2.new(1, 0, 0, 1)
		content.Position = UDim2.new(0, 0, 0, 0)
		content.Size = UDim2.new(1, 0, 1, -(barH + 1))
	elseif layout == "Right" then
		sidebar.Position = UDim2.new(1, -sidebarW, 0, 0)
		sidebar.Size = UDim2.new(0, sidebarW, 1, 0)
		divider.Position = UDim2.new(1, -(sidebarW + 1), 0, 0)
		divider.Size = UDim2.new(0, 1, 1, 0)
		content.Position = UDim2.new(0, 0, 0, 0)
		content.Size = UDim2.new(1, -(sidebarW + 1), 1, 0)
	else
		sidebar.Position = UDim2.new(0, 0, 0, 0)
		sidebar.Size = UDim2.new(0, sidebarW, 1, 0)
		divider.Position = UDim2.new(0, sidebarW, 0, 0)
		divider.Size = UDim2.new(0, 1, 1, 0)
		content.Position = UDim2.new(0, sidebarW + 1, 0, 0)
		content.Size = UDim2.new(1, -(sidebarW + 1), 1, 0)
	end

	for _, tab in pairs(self.Tabs) do
		if tab.Button then
			if horizontal then
				tab.Button.Size = UDim2.new(0, 120, 0, Theme.Sizes.ButtonHeight)
			else
				tab.Button.Size = UDim2.new(1, Theme.Sizes.SidebarInset, 0, Theme.Sizes.ButtonHeight)
			end
			tab.Button.Visible = true
			if tab.ButtonLabel then
				local lbl = tab.ButtonLabel
				lbl.Visible = true
				if horizontal then
					lbl.TextXAlignment = Enum.TextXAlignment.Center
					lbl.TextYAlignment = Enum.TextYAlignment.Center
					if tab.Icon then
						lbl.Position = UDim2.new(0, 30, 0, 0)
						lbl.Size = UDim2.new(1, -40, 1, 0)
					else
						lbl.Position = UDim2.new(0, 0, 0, 0)
						lbl.Size = UDim2.new(1, 0, 1, 0)
					end
				else
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					local off = tab.Icon and 42 or 20
					lbl.Position = UDim2.new(0, off, 0, 0)
					lbl.Size = UDim2.new(1, -(off + 6), 1, 0)
				end
			end
			if tab.Icon then
				tab.Icon.Visible = true
				if horizontal then
					tab.Icon.Position = UDim2.new(0, 10, 0.5, 0)
				else
					tab.Icon.Position = UDim2.new(0, 20, 0.5, 0)
				end
			end

			local bar = tab.AccentBar
			if bar then
				tab.IndicatorHorizontal = horizontal
				local activeSize: UDim2
				local inactiveSize: UDim2
				if horizontal then
					bar.AnchorPoint = Vector2.new(0.5, 1)
					bar.Position = UDim2.new(0.5, 0, 1, -3)
					activeSize = UDim2.new(0, Theme.Sizes.AccentBarHeight * 1.25, 0, Theme.Sizes.AccentBarWidth)
					inactiveSize = UDim2.new(0, 0, 0, Theme.Sizes.AccentBarWidth)
				else
					bar.AnchorPoint = Vector2.new(0, 0.5)
					bar.Position = UDim2.new(0, 0, 0.5, 0)
					activeSize = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, Theme.Sizes.AccentBarHeight)
					inactiveSize = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, 0)
				end
				bar.Size = tab.IsActive and activeSize or inactiveSize
			end

			if tab.SearchBar then
				self:_positionSearchBar(tab, horizontal)
			end
		end
	end
end

function Window:_positionSearchBar(tab: any, horizontal: boolean)
	local bar = tab.SearchBar
	if not bar then
		return
	end
	-- UNIFIED RULE: side layouts (Left/Right) -> always RIGHT edge;
	-- stacked layouts (Top/Bottom) -> always TOP edge.
	if horizontal then
		bar.Size = UDim2.new(0, Theme.Sizes.AccentBarHeight * 1.25, 0, Theme.Sizes.AccentBarWidth)
		bar.AnchorPoint = Vector2.new(0.5, 0)
		bar.Position = UDim2.new(0.5, 0, 0, 0)
	else
		bar.Size = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, Theme.Sizes.AccentBarHeight)
		bar.AnchorPoint = Vector2.new(1, 0.5)
		bar.Position = UDim2.new(1, 0, 0.5, 0)
	end
end

function Window:_updateSearchIndicators(matchedTabs: {[string]: boolean}, active: boolean)
	for name, tab in pairs(self.Tabs) do
		local bar = tab.SearchBar
		if bar then
			if active and matchedTabs[name] then
				bar.Visible = true
				Effects.tween(bar, Theme.Anim.Fast, { BackgroundTransparency = 0.4 })
			else
				Effects.tween(bar, Theme.Anim.Fast, { BackgroundTransparency = 1 })
			end
		end
	end
end

function Window:SetSectionLayout(layout: string)
	self.SectionLayout = layout
	local stacked = (layout == "Stacked")

	-- restore any sections currently moved into the search overlay first
	self:_resetSearchMoves()

	for _, tab in pairs(self.Tabs) do
		local left = tab.LeftColumn
		local right = tab.RightColumn
		if left and right then
			if stacked then
				for _, col in ipairs({ left, right }) do
					for _, section in ipairs(col:GetChildren()) do
						if section:IsA("Frame") and string.sub(section.Name, 1, 8) == "Section_" then
							section.Parent = left
						end
					end
				end
				right.Visible = false
				left.Size = UDim2.new(1, 0, 0, 0)
			else
				for _, section in ipairs(left:GetChildren()) do
					if section:IsA("Frame") and string.sub(section.Name, 1, 8) == "Section_" then
						if section:GetAttribute("ColumnSide") == "Right" then
							section.Parent = right
						end
					end
				end
				right.Visible = true
				left.Size = UDim2.new(0.5, -3, 0, 0)
				right.Size = UDim2.new(0.5, -3, 0, 0)
			end
		end
	end

	local searchBox = self.SearchBox
	if searchBox and searchBox.Text ~= "" then
		self:_applySearch(searchBox.Text)
	end
end

function Window:SetUIScale(scale: number)
	self.UIScaleValue = scale
	if not self.Main then
		return
	end
	local uiScale = self.Main:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = create("UIScale", { Name = "WindowScale", Scale = scale, Parent = self.Main })
	end
	Effects.tween(uiScale, Theme.Anim.Normal, { Scale = scale })
end

function Window:SetScaleMode(mode: string)
	self.ScaleMode = mode
	local map = { ["Compact (85%)"] = 0.85, ["Standard (100%)"] = 1, ["Large (115%)"] = 1.15 }
	if mode == "Custom (Freeform)" then
		-- keep the user's current size; lock scale to 1 and enable drag-resize
		self:SetUIScale(1)
		self:SetFreeform(true)
	else
		self:SetFreeform(false)
		-- snap back to the exact startup dimensions before applying the preset scale
		if self.Main and self.InitialWindowSize then
			self.Main.Size = self.InitialWindowSize
		end
		self:SetUIScale(map[mode] or 1)
	end
end

function Window:_buildResizeHandles()
	if self.ResizeHandles then
		return
	end
	local main = self.Main
	if not main then
		return
	end
	self.ResizeHandles = {}

	local function makeHandle(name: string, anchor: Vector2, position: UDim2, size: UDim2, xEdge: string?, yEdge: string?)
		local handle = create("TextButton", {
			Name = name,
			AnchorPoint = anchor,
			Position = position,
			Size = size,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Active = true,
			Visible = false,
			ZIndex = 5,
			Parent = main,
		})
		table.insert(self.ResizeHandles, handle)
		handle.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				self._resizing = true
				self._xEdge = xEdge
				self._yEdge = yEdge
				self._resizeStart = Vector2.new(input.Position.X, input.Position.Y)
				self._resizeStartSize = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
				self._resizeStartPos = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
			end
		end)
	end

	-- 4 sides
	makeHandle("ResizeN", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 0), UDim2.new(1, -32, 0, 8), nil, "top")
	makeHandle("ResizeS", Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, 0), UDim2.new(1, -32, 0, 8), nil, "bottom")
	makeHandle("ResizeW", Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0), UDim2.new(0, 8, 1, -32), "left", nil)
	makeHandle("ResizeE", Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 8, 1, -32), "right", nil)
	-- 4 corners
	makeHandle("ResizeNW", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, 16, 0, 16), "left", "top")
	makeHandle("ResizeNE", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, 16, 0, 16), "right", "top")
	makeHandle("ResizeSW", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(0, 16, 0, 16), "left", "bottom")
	makeHandle("ResizeSE", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), UDim2.new(0, 16, 0, 16), "right", "bottom")

	local library = self.Library

	library:_track(UserInputService.InputChanged:Connect(function(input: InputObject)
		if not self._resizing or not self._resizeStart or not self._resizeStartSize or not self._resizeStartPos then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local delta = Vector2.new(input.Position.X, input.Position.Y) - self._resizeStart
		local rawViewport = (library and library.ScreenGui and library.ScreenGui.AbsoluteSize) or Vector2.new(1920, 1080)
		-- inset the max bounds by 20px per side so the window never touches the screen edge
		local viewport = rawViewport - Vector2.new(40, 40)
		local minW, minH = 500, 350
		local maxW = math.max(minW, viewport.X)
		local maxH = math.max(minH, viewport.Y)

		local startSize = self._resizeStartSize
		local startPos = self._resizeStartPos
		local newX, newY = startSize.X, startSize.Y
		local shiftX, shiftY = 0, 0

		-- horizontal: dragging the right edge grows size; the left edge grows it inversely
		if self._xEdge == "right" then
			newX = math.clamp(startSize.X + delta.X, minW, maxW)
			shiftX = (newX - startSize.X) / 2
		elseif self._xEdge == "left" then
			newX = math.clamp(startSize.X - delta.X, minW, maxW)
			shiftX = -(newX - startSize.X) / 2
		end

		-- vertical: same rule for bottom/top edges
		if self._yEdge == "bottom" then
			newY = math.clamp(startSize.Y + delta.Y, minH, maxH)
			shiftY = (newY - startSize.Y) / 2
		elseif self._yEdge == "top" then
			newY = math.clamp(startSize.Y - delta.Y, minH, maxH)
			shiftY = -(newY - startSize.Y) / 2
		end

		-- the frame is center-anchored, so moving a dragged edge also shifts the center
		main.Size = UDim2.fromOffset(math.round(newX), math.round(newY))
		main.Position = UDim2.new(0.5, math.round(startPos.X + shiftX), 0.5, math.round(startPos.Y + shiftY))
	end))

	library:_track(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self._resizing = false
			self._resizeStart = nil
			self._resizeStartSize = nil
			self._resizeStartPos = nil
		end
	end))
end

function Window:SetFreeform(enabled: boolean)
	self.Freeform = enabled
	if enabled and not self.ResizeHandles then
		self:_buildResizeHandles()
	end
	if self.ResizeHandles then
		for _, handle in ipairs(self.ResizeHandles) do
			handle.Visible = enabled
		end
	end
end

function Window:SetCornerRadius(radius: number)
	self.CornerRadius = radius
	if not self.Main then
		return
	end
	-- scope: the main window frame, the background image, and section cards ONLY
	local mainCorner = self.Main:FindFirstChildOfClass("UICorner")
	if mainCorner then
		mainCorner.CornerRadius = UDim.new(0, radius)
	end
	if self.BackgroundImage then
		local bgCorner = self.BackgroundImage:FindFirstChildOfClass("UICorner")
		if bgCorner then
			bgCorner.CornerRadius = UDim.new(0, radius)
		end
	end
	local function walk(inst: Instance)
		for _, child in ipairs(inst:GetChildren()) do
			if child:IsA("GuiObject") and child:GetAttribute("IsCard") == true then
				local c = child:FindFirstChildOfClass("UICorner")
				if c then
					c.CornerRadius = UDim.new(0, radius)
				end
			end
			walk(child)
		end
	end
	walk(self.Main)
end
function Window:Minimize()
	if self.IsMinimized then
		return
	end
	self.IsMinimized = true

	if self.Main then
		self.Main.Visible = false
	end

	if not self.MinimizeWidget then
		self:_buildMinimizeWidget()
	end

	local widget = self.MinimizeWidget
	if widget then
		widget.Visible = true
		widget.BackgroundTransparency = 1
		local icon = widget:FindFirstChild("Icon")
		if icon then
			icon.ImageTransparency = 1
		end
		Effects.tween(widget, Theme.Anim.Normal, { BackgroundTransparency = 0 })
		if icon then
			Effects.tween(icon, Theme.Anim.Normal, { ImageTransparency = 0 })
		end
	end
end

function Window:Restore()
	if not self.IsMinimized then
		return
	end
	self.IsMinimized = false

	if self.MinimizeWidget then
		self.MinimizeWidget.Visible = false
	end

	if self.Main then
		self.Main.Visible = true
	end
end

function Window:_buildMinimizeWidget()
	local library = self.Library
	local parent = library and library.ScreenGui
	if not parent then
		return
	end

	local widget = create("TextButton", {
		Name = "MinimizeWidget",
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0, 24, 0, 120),
		BackgroundColor3 = Theme.Colors.Component,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = parent,
	})
	addCorner(widget, 12)
	addStroke(widget, Theme.Colors.Accent, 1, 0.2)

	local icon = create("ImageLabel", {
		Name = "Icon",
		Size = UDim2.new(0.85, 0, 0.85, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = STAR_EYE_IMAGE_ID,
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Parent = widget,
	})

	self.MinimizeWidget = widget
	if library then
		table.insert(library.MinimizeWidgets, widget)
	end

	widget.MouseButton1Click:Connect(function()
		self:Restore()
	end)

	widget.MouseEnter:Connect(function()
		Effects.tween(widget, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.ComponentDeep })
	end)
	widget.MouseLeave:Connect(function()
		Effects.tween(widget, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.Component })
	end)

	-- draggable
	local dragging = false
	local dragStart: Vector2? = nil
	local startPos: UDim2? = nil

	widget.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = widget.Position
		end
	end)

	if library then
		library:_track(UserInputService.InputChanged:Connect(function(input: InputObject)
			if not dragging or not dragStart or not startPos then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			widget.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end))

		library:_track(UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
				dragStart = nil
				startPos = nil
			end
		end))
	end
end

function Window:_buildUnloadModal()
	if self.UnloadModal then
		return
	end

	local library = self.Library
	local parent = library and library.ScreenGui
	if not parent then
		return
	end

	local scrim = create("TextButton", {
		Name = "UnloadScrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.ModalScrim,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 100,
		Parent = parent,
	})

	local modal = create("Frame", {
		Name = "UnloadModal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 320, 0, 150),
		BackgroundColor3 = Theme.Colors.Background,
		BorderSizePixel = 0,
		ZIndex = 101,
		Parent = scrim,
	})
	addCorner(modal, Theme.Sizes.Corner)
	addStroke(modal, Theme.Colors.Stroke, 1, 0.2)

	create("TextLabel", {
		Name = "ModalTitle",
		Position = UDim2.new(0, 16, 0, 14),
		Size = UDim2.new(1, -32, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Header,
		Text = "Unload SakkaHub",
		TextSize = 16,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		ZIndex = 102,
		Parent = modal,
	})

	create("TextLabel", {
		Name = "ModalBody",
		Position = UDim2.new(0, 16, 0, 44),
		Size = UDim2.new(1, -32, 0, 40),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = "Do you want to unload the script?",
		TextSize = 15,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextScaled = false,
		ZIndex = 102,
		Parent = modal,
	})

	local noBtn = create("TextButton", {
		Name = "No",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -14),
		Size = UDim2.new(0, 90, 0, 32),
		BackgroundColor3 = Theme.Colors.Component,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Font = Theme.Fonts.Body,
		Text = "No",
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
		TextScaled = false,
		ZIndex = 102,
		Parent = modal,
	})
	addCorner(noBtn, Theme.Sizes.ControlCorner)

	local yesBtn = create("TextButton", {
		Name = "Yes",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -116, 1, -14),
		Size = UDim2.new(0, 90, 0, 32),
		BackgroundColor3 = Theme.Colors.Accent,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Font = Theme.Fonts.Body,
		Text = "Yes",
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
		TextScaled = false,
		ZIndex = 102,
		Parent = modal,
	})
	addCorner(yesBtn, Theme.Sizes.ControlCorner)

	self.UnloadModal = scrim

	Effects.tween(scrim, Theme.Anim.Normal, { BackgroundTransparency = 0.5 })

	noBtn.MouseButton1Click:Connect(function()
		self:_closeModal(scrim)
	end)

	yesBtn.MouseButton1Click:Connect(function()
		self:_closeModal(scrim)
		if library then
			library:Unload()
		end
	end)
end

function Window:_closeModal(scrim: Instance)
	self.UnloadModal = nil
	local tween = Effects.tween(scrim, Theme.Anim.Normal, { BackgroundTransparency = 1 })
	tween.Completed:Once(function()
		scrim:Destroy()
	end)
end

function Window:_buildKeySystem(expectedKey: string, keyLink: string)
	local library = self.Library
	local parent = library and library.ScreenGui
	if not parent then
		return
	end

	if self.Main then
		self.Main.Visible = false
	end

	local scrim = create("Frame", {
		Name = "KeyScrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.ModalScrim,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Active = false,
		ZIndex = 100,
		Parent = parent,
	})

	local modal = create("Frame", {
		Name = "KeyModal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 340, 0, 200),
		BackgroundColor3 = Theme.Colors.Background,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 101,
		Parent = scrim,
	})
	addCorner(modal, Theme.Sizes.Corner)
	addStroke(modal, Theme.Colors.Accent, 1, 0.1)

	local keyList = create("Frame", {
		Name = "KeyList",
		Position = UDim2.new(0, 20, 0, 14),
		Size = UDim2.new(1, -40, 1, -28),
		BackgroundTransparency = 1,
		Active = false,
		ZIndex = 102,
		Parent = modal,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 8),
		Parent = keyList,
	})
	create("UIPadding", { PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0), PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), Parent = keyList })

	create("TextLabel", {
		Name = "KeyTitle",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Header,
		Text = self.Title .. "  |  Key System",
		TextSize = 16,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		LayoutOrder = 1,
		ZIndex = 102,
		Parent = keyList,
	})

	local keyBox = create("TextBox", {
		Name = "KeyBox",
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 2,
		BackgroundColor3 = Theme.Colors.Component,
		BorderSizePixel = 0,
		Font = Theme.Fonts.Body,
		Text = "",
		PlaceholderText = "Enter your key...",
		PlaceholderColor3 = Color3.fromRGB(140, 140, 145),
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		ClearTextOnFocus = false,
		ZIndex = 102,
		Parent = keyList,
	})
	addCorner(keyBox, Theme.Sizes.ControlCorner)
	addPadding(keyBox, 0, 10, 0, 10)

	local errorLabel = create("TextLabel", {
		Name = "Error",
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = "",
		TextSize = 13,
		TextColor3 = Theme.Colors.Error,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		LayoutOrder = 3,
		ZIndex = 102,
		Parent = keyList,
	})

	local discordBtn = create("TextButton", {
		Name = "Discord",
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 4,
		BackgroundColor3 = Theme.Colors.DropdownBar,
		AutoButtonColor = false,
		Font = Theme.Fonts.Body,
		Text = "Join Discord Server",
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
		TextScaled = false,
		Modal = false,
		ZIndex = 102,
		Parent = keyList,
	})
	addCorner(discordBtn, 6)

	local buttonRow = create("Frame", {
		Name = "ButtonRow",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		ZIndex = 102,
		Parent = keyList,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = buttonRow,
	})

	local getBtn = create("TextButton", {
		Name = "GetKey",
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundColor3 = Theme.Colors.DropdownBar,
		AutoButtonColor = false,
		Font = Theme.Fonts.Body,
		Text = "Get Key",
		TextSize = 14,
		TextColor3 = Theme.Colors.TextMuted,
		TextScaled = false,
		Modal = false,
		LayoutOrder = 1,
		ZIndex = 102,
		Parent = buttonRow,
	})
	addCorner(getBtn, 6)

	local checkBtn = create("TextButton", {
		Name = "CheckKey",
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundColor3 = Theme.Colors.DropdownBar,
		AutoButtonColor = false,
		Font = Theme.Fonts.Body,
		Text = "Check Key",
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
		TextScaled = false,
		Modal = false,
		LayoutOrder = 2,
		ZIndex = 102,
		Parent = buttonRow,
	})
	addCorner(checkBtn, 6)

	local function bindTint(button: TextButton)
		button.MouseEnter:Connect(function()
			Effects.tween(button, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.ComponentDeep })
			Effects.tween(button, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
		end)
		button.MouseLeave:Connect(function()
			Effects.tween(button, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.DropdownBar })
			Effects.tween(button, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
		end)
	end

	bindTint(getBtn)
	bindTint(checkBtn)
	bindTint(discordBtn)

	-- draggable key modal
	local dragging = false
	local dragStart: Vector2? = nil
	local startPos: UDim2? = nil

	modal.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = modal.Position
		end
	end)

	if library then
		library:_track(UserInputService.InputChanged:Connect(function(input: InputObject)
			if not dragging or not dragStart or not startPos then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			modal.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end))

		library:_track(UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
				dragStart = nil
				startPos = nil
			end
		end))
	end

	discordBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard("https://discord.gg/yourlink")
		end
		if library then
			library:Notify({ Title = "Discord", Content = "Invite link copied.", Duration = 3 })
		end
	end)

	getBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(keyLink)
		end
		if library then
			library:Notify({ Title = "Key System", Content = "Key link copied: " .. keyLink, Duration = 4 })
		end
	end)

	checkBtn.MouseButton1Click:Connect(function()
		local entered = string.gsub(keyBox.Text, "%s", "")
		local expected = string.gsub(expectedKey, "%s", "")

		if entered == expected then
			scrim:Destroy()
			self:_showLoadingScreen()
		else
			errorLabel.Text = "Invalid Key!"
			keyBox.Text = ""
		end
	end)
end

function Window:_ensureSearchFrame(): ScrollingFrame?
	if self.SearchResultsFrame and self.SearchResultsFrame.Parent then
		return self.SearchResultsFrame
	end
	local content = self.Content
	if not content then
		return nil
	end

	local frame = create("ScrollingFrame", {
		Name = "SearchResultsFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 5,
		Parent = content,
	})
	addPadding(frame, 10, 0, 10, 0)

	local columns = create("Frame", {
		Name = "SearchColumns",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = frame,
	})
	-- horizontal padding lives on the inner (non-scrolling) columns frame so the
	-- scale-width columns actually shrink to fit; UIPadding on the ScrollingFrame
	-- would only shift them and let the right column overflow the window border.
	addPadding(columns, 0, 16, 0, 14)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 6),
		Parent = columns,
	})

	local left = create("Frame", {
		Name = "ResultsLeft",
		Size = UDim2.new(0.5, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = columns,
	})
	addList(left, 6, Enum.HorizontalAlignment.Center)

	local right = create("Frame", {
		Name = "ResultsRight",
		Size = UDim2.new(0.5, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = columns,
	})
	addList(right, 6, Enum.HorizontalAlignment.Center)

	self.SearchResultsFrame = frame
	self.SearchResultsColumns = columns
	self.SearchResultsLeft = left
	self.SearchResultsRight = right
	return frame
end

function Window:_applySearch(query: string)
	query = string.lower(string.gsub(query, "^%s*(.-)%s*$", "%1"))
	local active = query ~= ""

	-- restore anything a previous search moved or hid (keeps original parenting intact)
	self:_resetSearchMoves()

	local results = self:_ensureSearchFrame()
	if not results then
		return
	end

	-- hide all standard tab pages while searching
	for _, tab in pairs(self.Tabs) do
		if tab.Page then
			tab.Page.Visible = (not active) and (self.ActiveTab == tab.Name)
		end
	end

	if not active then
		results.Visible = false
		self:_updateSearchIndicators({}, false)
		return
	end

	local leftover = results:FindFirstChild("NoResults")
	if leftover then
		leftover:Destroy()
	end

	results.Visible = true

	local stacked = self.SectionLayout == "Stacked"
	local left = self.SearchResultsLeft
	local right = self.SearchResultsRight
	if left and right then
		right.Visible = not stacked
		left.Size = stacked and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -3, 0, 0)
	end

	local order = 0
	local useLeft = true
	local matchedTabs: {[string]: boolean} = {}

	for _, tab in pairs(self.Tabs) do
		local layer = tab.Page:FindFirstChild("TransitionLayer")
		local columns = layer and layer:FindFirstChild("Columns")
		if columns then
			for _, column in ipairs(columns:GetChildren()) do
				if column:IsA("Frame") then
					for _, section in ipairs(column:GetChildren()) do
						if section:IsA("Frame") and string.sub(section.Name, 1, 8) == "Section_" then
							local heading = section:FindFirstChild("Heading")
							local sectionName = heading and string.lower(heading.Text) or ""
							local sectionMatches = string.find(sectionName, query, 1, true) ~= nil

							local anyChildMatch = false
							for _, control in ipairs(section:GetChildren()) do
								if control:IsA("GuiObject") and control ~= heading then
									local lbl = control:FindFirstChild("Label", true)
									local text = lbl and string.lower(lbl.Text) or ""
									if string.find(text, query, 1, true) ~= nil then
										anyChildMatch = true
									end
								end
							end

							if sectionMatches or anyChildMatch then
								matchedTabs[tab.Name] = true
								order += 1

								-- MOVE the original section so all callbacks and state stay live
								table.insert(self._searchMoves, {
									section = section,
									parent = column,
									layoutOrder = section.LayoutOrder,
								})

								section.LayoutOrder = order
								section.Visible = true

								local target = left or results
								if not stacked then
									target = useLeft and (left or results) or (right or results)
									useLeft = not useLeft
								end
								section.Parent = target

								-- component-only match: hide non-matching children
								if not sectionMatches then
									for _, child in ipairs(section:GetChildren()) do
										if child:IsA("GuiObject") and child ~= heading then
											local lbl = child:FindFirstChild("Label", true)
											local text = lbl and string.lower(lbl.Text) or ""
											if string.find(text, query, 1, true) == nil and child.Visible then
												table.insert(self._searchHidden, child)
												child.Visible = false
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	self:_updateSearchIndicators(matchedTabs, true)

	if order == 0 then
		create("TextLabel", {
			Name = "NoResults",
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Font = Theme.Fonts.Body,
			Text = "No results found",
			TextSize = 14,
			TextColor3 = Theme.Colors.TextMuted,
			TextScaled = false,
			Parent = results,
		})
	end
end

function Window:_resetSearchMoves()
	if self._searchMoves then
		for _, record in ipairs(self._searchMoves) do
			local section = record.section
			if section and section.Parent then
				section.LayoutOrder = record.layoutOrder
				section.Visible = true
				section.Parent = record.parent
			end
		end
	end
	self._searchMoves = {}

	if self._searchHidden then
		for _, child in ipairs(self._searchHidden) do
			if child and child.Parent then
				child.Visible = true
			end
		end
	end
	self._searchHidden = {}
end

function Window:_showLoadingScreen()
	local library = self.Library
	local parent = library and library.ScreenGui
	if not parent then
		return
	end

	local overlay = create("Frame", {
		Name = "LoadingOverlay",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(15, 15, 20),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 300,
		Parent = parent,
	})

	local blur = create("BlurEffect", {
		Name = "SakkaLoadingBlur",
		Size = 16,
		Parent = game:GetService("Lighting"),
	})

	-- ===== STAR-EYE LOGO (ImageLabel, pixel-perfect 1:1 asset) =====
	local logo = create("ImageLabel", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.36, 0),
		Size = UDim2.new(0, 280, 0, 280),
		BackgroundTransparency = 1,
		Image = STAR_EYE_IMAGE_ID,
		ScaleType = Enum.ScaleType.Fit,
		ImageTransparency = 1,
		ZIndex = 301,
		Parent = overlay,
	})
	local logoScale = create("UIScale", { Scale = 0.85, Parent = logo })
	Effects.tween(logo, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0 })
	Effects.tween(logoScale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })

	-- ===== SEQUENTIAL MESSAGES (fade in from black) =====
	local messages = {
		"Initializing Sakka Core Engine...",
		"Decrypting payload & verifying security tokens...",
		"Establishing neural system hooks & module tables...",
		"Applying user theme configurations...",
		"System Operational. Welcome!",
	}

	local msgHolder = create("Frame", {
		Name = "Messages",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.58, 0),
		Size = UDim2.new(0, 480, 0, 160),
		BackgroundTransparency = 1,
		ZIndex = 301,
		Parent = overlay,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 6),
		Parent = msgHolder,
	})

	local labels = {}
	for i, text in ipairs(messages) do
		local lbl = create("TextLabel", {
			Name = "Msg" .. i,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextScaled = false,
			LayoutOrder = i,
			ZIndex = 301,
			Parent = msgHolder,
		})
		table.insert(labels, lbl)
	end

	-- ===== PERCENTAGE COUNTER ONLY (no bar) =====
	local pctLabel = create("TextLabel", {
		Name = "Percent",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.58, 0 + 160 + 8),
		Size = UDim2.new(0, 200, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "0%",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = false,
		ZIndex = 301,
		Parent = overlay,
	})

	-- ===== TIMELINE =====
	local STEP = 0.52
	local TOTAL = STEP * #messages

	local progress = create("NumberValue", { Value = 0, Parent = overlay })
	progress:GetPropertyChangedSignal("Value"):Connect(function()
		pctLabel.Text = tostring(math.floor(progress.Value * 100 + 0.5)) .. "%"
	end)
	TweenService:Create(progress, TweenInfo.new(TOTAL, Enum.EasingStyle.Linear), { Value = 1 }):Play()

	task.spawn(function()
		for _, lbl in ipairs(labels) do
			Effects.tween(lbl, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
			})
			task.wait(STEP)
			if not overlay.Parent then
				blur:Destroy()
				return
			end
		end

		task.wait(0.1)
		if not overlay.Parent then
			blur:Destroy()
			return
		end

		if self.Main then
			self.Main.Visible = true
			self.Main.BackgroundTransparency = 1
			Effects.tween(self.Main, Theme.Anim.Normal, { BackgroundTransparency = 0 })
		end

		local warpInfo = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
		TweenService:Create(overlay, warpInfo, { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(overlay:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, warpInfo, { TextTransparency = 1 }):Play()
			elseif d:IsA("ImageLabel") then
				TweenService:Create(d, warpInfo, { ImageTransparency = 1 }):Play()
			elseif d:IsA("UIStroke") then
				TweenService:Create(d, TweenInfo.new(0.45), { Transparency = 1 }):Play()
			elseif d:IsA("GuiObject") then
				TweenService:Create(d, warpInfo, { BackgroundTransparency = 1 }):Play()
			end
		end

		local warpScale = create("UIScale", { Scale = 1, Parent = overlay })
		local st = TweenService:Create(warpScale, warpInfo, { Scale = 15 })
		st:Play()
		st.Completed:Once(function()
			overlay:Destroy()
			blur:Destroy()
		end)
	end)
end

function Window:BuildProfileCard(parent: Instance)
	local card = create("Frame", {
		Name = "CharacterCard",
		Size = UDim2.new(1, 0, 0, Theme.Sizes.CardHeight),
		BackgroundColor3 = Theme.Colors.ComponentDeep,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Parent = parent,
	})
	addCorner(card, Theme.Sizes.CardCorner)
	addStroke(card, Theme.Colors.Stroke, 1, 0.35)
	addPadding(card, 8, 8, 8, 8)
	addList(card, 4)
	self.Card = card

	local avatar = create("ImageLabel", {
		Name = "Avatar",
		Size = UDim2.new(0, 56, 0, 56),
		BackgroundColor3 = Theme.Colors.Component,
		BorderSizePixel = 0,
		Image = "",
		LayoutOrder = 0,
		Parent = card,
	})
	addCorner(avatar, 28)
	self.Avatar = avatar

	local labels: {[string]: TextLabel} = {}
	local order = 0

	local function makeLabel(key: string, initial: string): TextLabel
		order += 1
		local label = create("TextLabel", {
			Name = key,
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Font = Theme.Fonts.Body,
			Text = initial,
			TextSize = 11,
			TextColor3 = Theme.Colors.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = order,
			Parent = card,
		})
		labels[key] = label
		return label
	end

	makeLabel("Client", "Client: -")
	makeLabel("KeyType", "Key: -")
	makeLabel("TimeLeft", "Time Left: -")
	makeLabel("Executions", "Executions: -")

	self.CardLabels = labels

	if LocalPlayer then
		self:SetAvatar("rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=100&h=100")
	end
end

function Window:SetAvatar(imageSource: string)
	if self.Avatar then
		self.Avatar.Image = imageSource
	end
end

function Window:LoadLocalAvatar()
	if not LocalPlayer then
		return
	end
	local ok, url = pcall(function()
		return Players:GetUserThumbnailAsync(
			LocalPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
	end)
	if ok and type(url) == "string" then
		self:SetAvatar(url)
	else
		self:SetAvatar("rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=100&h=100")
	end
end

function Window:SetCharacterInfo(info: CharacterInfo)
	local labels = self.CardLabels
	if not labels then
		return
	end
	if info.Client ~= nil then
		labels.Client.Text = "Client: " .. info.Client
	end
	if info.KeyType ~= nil then
		labels.KeyType.Text = "Key: " .. info.KeyType
	end
	if info.TimeLeft ~= nil then
		labels.TimeLeft.Text = "Time Left: " .. info.TimeLeft
	end
	if info.Executions ~= nil then
		labels.Executions.Text = "Executions: " .. tostring(info.Executions)
	end
end

function Window:_bindDrag()
	local header = self.Header
	local main = self.Main
	local dragStart: Vector2? = nil
	local startPos: UDim2? = nil
	local activeTween: Tween? = nil

	header.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		self.Dragging = true
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		startPos = main.Position
	end)

	local library = self.Library

	library:_track(UserInputService.InputChanged:Connect(function(input: InputObject)
		if not self.Dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if not dragStart or not startPos then
			return
		end

		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
		local target = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)

		if activeTween then
			activeTween:Cancel()
		end
		activeTween = Effects.tween(
			main,
			TweenInfo.new(self.DragSmoothing, Enum.EasingStyle.Linear),
			{ Position = target }
		)
	end))

	library:_track(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = false
			dragStart = nil
			startPos = nil
		end
	end))
end

function Window:CreateTab(name: string, iconId: string?)
	assert(type(name) == "string", "Window:CreateTab(name: string)")

	local existing = self.Tabs[name]
	if existing then
		return existing
	end

	self.TabOrder += 1

	local tab = setmetatable({}, Tab)
	tab.Name = name
	tab.Window = self
	tab.Order = 0
	tab.Flags = {}
	tab.IsActive = false

	-- sidebar navigation button
	local horizontal = (self.ButtonLayout == "Top" or self.ButtonLayout == "Bottom")
	local nav = create("TextButton", {
		Name = "Tab_" .. name,
		Size = horizontal and UDim2.new(0, 120, 0, Theme.Sizes.ButtonHeight) or UDim2.new(1, Theme.Sizes.SidebarInset, 0, Theme.Sizes.ButtonHeight),
		BackgroundColor3 = Theme.Colors.HoverTint,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = self.TabOrder,
		Parent = self.Sidebar,
	})
	addCorner(nav, Theme.Sizes.ControlCorner)

	local accentBar = create("Frame", {
		Name = "Accent",
		AnchorPoint = horizontal and Vector2.new(0.5, 1) or Vector2.new(0, 0.5),
		Position = horizontal and UDim2.new(0.5, 0, 1, -3) or UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, 0),
		BackgroundColor3 = Theme.Colors.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = nav,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accentBar })
	tab.IndicatorHorizontal = horizontal

	-- search-result indicator: appears on the OPPOSITE edge from the active bar on
	-- any tab that holds a match while a search query is active
	local searchBar = create("Frame", {
		Name = "SearchIndicator",
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Theme.Colors.Accent,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Visible = false,
		Parent = nav,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = searchBar })
	tab.SearchBar = searchBar
	self:_positionSearchBar(tab, horizontal)

	-- indicator size depends on the current nav orientation (vertical bar vs horizontal underline)
	local function activeBarSize(): UDim2
		if tab.IndicatorHorizontal then
			return UDim2.new(0, Theme.Sizes.AccentBarHeight * 1.25, 0, Theme.Sizes.AccentBarWidth)
		end
		return UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, Theme.Sizes.AccentBarHeight)
	end

	local function inactiveBarSize(): UDim2
		if tab.IndicatorHorizontal then
			return UDim2.new(0, 0, 0, Theme.Sizes.AccentBarWidth)
		end
		return UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, 0)
	end

	local textOffset = 20
	local icon: ImageLabel? = nil

	if iconId and iconId ~= "" then
		icon = create("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 20, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
			Image = iconId,
			ImageColor3 = Theme.Colors.TextMuted,
			Parent = nav,
		})
		textOffset = 42
	end

	local navLabel = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, textOffset, 0, 0),
		Size = UDim2.new(1, -(textOffset + 6), 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = name,
		TextSize = Theme.Sizes.ButtonTextSize,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		Visible = true,
		Parent = nav,
	})

	tab.Button = nav
	tab.Icon = icon
	tab.ButtonLabel = navLabel
	tab.AccentBar = accentBar

	-- page (2-column side-by-side layout, with transition layer)
	local page = create("ScrollingFrame", {
		Name = "Page_" .. name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = self.Content,
	})
	addPadding(page, 10, 0, 10, 0)

	local transitionLayer = create("CanvasGroup", {
		Name = "TransitionLayer",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		GroupTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Parent = page,
	})

	local columns = create("Frame", {
		Name = "Columns",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = transitionLayer,
	})
	addPadding(columns, 0, 14, 0, 14)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 6),
		Parent = columns,
	})

	local leftColumn = create("Frame", {
		Name = "LeftColumn",
		Size = UDim2.new(0.5, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = columns,
	})
	addList(leftColumn, 6, Enum.HorizontalAlignment.Center)

	local rightColumn = create("Frame", {
		Name = "RightColumn",
		Size = UDim2.new(0.5, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = columns,
	})
	addList(rightColumn, 6, Enum.HorizontalAlignment.Center)

	tab.Page = page
	tab.TransitionLayer = transitionLayer
	tab.Columns = columns
	tab.LeftColumn = leftColumn
	tab.RightColumn = rightColumn
	tab.TargetColumn = leftColumn
	tab.CurrentSection = nil

	-- active state: background stays fully transparent; only the red pill bar marks it.
	local function activate()
		tab.IsActive = true
		Effects.tween(nav, Theme.Anim.Fast, { BackgroundTransparency = 1 })
		Effects.tween(navLabel, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
		if tab.Icon then
			Effects.tween(tab.Icon, Theme.Anim.Fast, { ImageColor3 = Theme.Colors.Text })
		end
		accentBar.Visible = true
		Effects.tween(accentBar, Theme.Anim.Fast, {
			BackgroundTransparency = 0,
			Size = activeBarSize(),
		})
	end

	local function deactivate()
		tab.IsActive = false
		Effects.tween(nav, Theme.Anim.Fast, { BackgroundTransparency = 1 })
		Effects.tween(navLabel, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
		if tab.Icon then
			Effects.tween(tab.Icon, Theme.Anim.Fast, { ImageColor3 = Theme.Colors.TextMuted })
		end
		Effects.tween(accentBar, Theme.Anim.Fast, {
			BackgroundTransparency = 1,
			Size = inactiveBarSize(),
		})
	end

	tab.Activate = activate
	tab.Deactivate = deactivate

	nav.MouseButton1Click:Connect(function()
		if self.SearchBox and self.SearchBox.Text ~= "" then
			self.SearchBox.Text = ""
		end
		self:SelectTab(name)
	end)

	-- hover works for BOTH active and inactive tabs; the gray tint only exists while hovered.
	nav.MouseEnter:Connect(function()
		Effects.tween(nav, Theme.Anim.Fast, { BackgroundTransparency = 0.9 })
		Effects.tween(navLabel, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
		if not tab.IsActive then
			accentBar.Visible = true
			Effects.tween(accentBar, Theme.Anim.Fast, {
				BackgroundTransparency = 0.5,
				Size = activeBarSize(),
			})
		end
	end)

	nav.MouseLeave:Connect(function()
		Effects.tween(nav, Theme.Anim.Fast, { BackgroundTransparency = 1 })
		if tab.IsActive then
			-- keep red bar, keep white text
			Effects.tween(navLabel, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
			Effects.tween(accentBar, Theme.Anim.Fast, {
				BackgroundTransparency = 0,
				Size = activeBarSize(),
			})
		else
			Effects.tween(navLabel, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
			Effects.tween(accentBar, Theme.Anim.Fast, {
				BackgroundTransparency = 1,
				Size = inactiveBarSize(),
			})
		end
	end)

	self.Tabs[name] = tab

	-- default-select the first NON-Settings tab (Settings is created first but should not be default)
	if self.ActiveTab == nil and name ~= "Settings" then
		self:SelectTab(name)
	end

	return tab
end

function Window:SelectTab(name: string)
	local target = self.Tabs[name]
	if not target then
		return
	end

	if self.ActiveTab == name then
		return
	end

	for tabName, tab in pairs(self.Tabs) do
		if tabName == name then
			tab.Page.Visible = true

			local layer = tab.TransitionLayer
			if layer then
				layer.GroupTransparency = 1
				layer.Position = UDim2.new(0, 0, 0, 10)
				Effects.tween(layer, Theme.Anim.Page, {
					GroupTransparency = 0,
					Position = UDim2.new(0, 0, 0, 0),
				})
			end

			if tab.Activate then
				tab.Activate()
			end
		else
			if tab.IsActive and tab.Deactivate then
				tab.Deactivate()
			end
			tab.Page.Visible = false
		end
	end

	self.ActiveTab = name
end

function Window:Toggle()
	local gui = self.Library and self.Library.ScreenGui
	if gui then
		gui.Enabled = not gui.Enabled
	end
end

function Window:Destroy()
	if self.BorderTween then
		self.BorderTween:Cancel()
	end
	if self.Main then
		self.Main:Destroy()
	end
end

-- =========================================================================================
--  10. TAB - CONTROL FACTORY
-- =========================================================================================

function Tab:_nextOrder(): number
	self.Order += 1
	return self.Order
end

function Tab:_target(): Instance
	return self.CurrentSection or self.TargetColumn or self.LeftColumn or self.Page
end

function Tab:AddSection(text: string, columnName: string?)
	if columnName == "Left" then
		self._columnToggle = true
	elseif columnName == "Right" then
		self._columnToggle = false
	else
		self._columnToggle = not self._columnToggle
	end
	local side = self._columnToggle and "Left" or "Right"
	local stacked = self.Window and self.Window.SectionLayout == "Stacked"
	local column = (stacked or side == "Left") and self.LeftColumn or self.RightColumn
	self.TargetColumn = column

	local section = create("Frame", {
		Name = "Section_" .. text,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Card,
		BackgroundTransparency = 0.05,
		ClipsDescendants = true,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		Parent = column,
	})
	addCorner(section, Theme.Sizes.CardCorner)
	addList(section, 6, Enum.HorizontalAlignment.Center)
	addPadding(section, 10, 12, 10, 12)
	section:SetAttribute("ColumnSide", side)
	section:SetAttribute("IsCard", true)
	create("TextLabel", {
		Name = "Heading",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Header,
		Text = string.upper(text),
		TextSize = 12,
		TextColor3 = Theme.Colors.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextScaled = false,
		LayoutOrder = 0,
		Parent = section,
	})

	self.CurrentSection = section
	return section
end

function Tab:AddLabel(text: string)
	local label = create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 12,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})
	return label
end

function Tab:AddButton(config: ButtonConfig)
	local text = config.Text or "Button"
	local callback = config.Callback

	local row = create("TextButton", {
		Name = "Button_" .. text,
		Size = UDim2.new(1, 0, 0, Theme.Sizes.ControlHeight),
		BackgroundColor3 = Theme.Colors.Component,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})
	addCorner(row, Theme.Sizes.ControlCorner)

	local bar = create("Frame", {
		Name = "Accent",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, 0),
		BackgroundColor3 = Theme.Colors.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = row,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 14,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextScaled = false,
		Parent = row,
	})

	Effects.bindHover(row, label, bar)
	addPaidBadge(label, config)

	row.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback)
		end
	end)

	if config.DependsOn then
		bindDepends(config.DependsOn, row)
	end

	return row
end

function Tab:AddToggle(config: ToggleConfig)
	local text = config.Text or "Toggle"
	local callback = config.Callback

	local row = create("TextButton", {
		Name = "Toggle_" .. text,
		Size = UDim2.new(1, 0, 0, Theme.Sizes.ControlHeight),
		BackgroundColor3 = Theme.Colors.HoverTint,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})
	addCorner(row, Theme.Sizes.ControlCorner)

	local bar = create("Frame", {
		Name = "Accent",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, Theme.Sizes.AccentBarWidth, 0, 0),
		BackgroundColor3 = Theme.Colors.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = row,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 13,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local switch = create("Frame", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 38, 0, 20),
		BackgroundColor3 = Theme.Colors.Track,
		BorderSizePixel = 0,
		Parent = row,
	})
	addCorner(switch, 10)

	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = Theme.Colors.TextMuted,
		BorderSizePixel = 0,
		Parent = switch,
	})
	addCorner(knob, 7)

	Effects.bindHover(row, label, bar)
	addPaidBadge(label, config)

	local object: any = {}
	object.Value = config.Default == true
	object.Instance = row
	object.Type = "Toggle"
	object.Interactable = true

	function object:SetInteractable(state: boolean)
		self.Interactable = state
		local dim = state and 0 or 0.5
		label.TextTransparency = dim
		Effects.tween(switch, Theme.Anim.Fast, { BackgroundTransparency = dim })
		Effects.tween(knob, Theme.Anim.Fast, { BackgroundTransparency = dim })
	end

	function object:IsInteractable(): boolean
		return self.Interactable ~= false
	end

	function object:Set(value: boolean, fire: boolean?)
		self.Value = value

		-- run the callback FIRST so any accent change it triggers is reflected
		-- before we color the switch/knob (fixes Custom toggle keeping the old accent)
		if fire ~= false and callback then
			callback(value)
		end

		Effects.tween(switch, Theme.Anim.Fast, {
			BackgroundColor3 = value and Theme.Colors.Accent or Theme.Colors.Track,
		})
		Effects.tween(knob, Theme.Anim.Fast, {
			Position = value and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = value and Theme.Colors.Text or Theme.Colors.TextMuted,
		})

		refreshDependents(self)
	end

	function object:Get(): boolean
		return self.Value
	end

	row.MouseButton1Click:Connect(function()
		if object.Interactable == false then
			return
		end
		object:Set(not object.Value)
	end)

	object:Set(object.Value, false)
	self.Flags[text] = object
	if config.DependsOn then
		bindDepends(config.DependsOn, row)
	end

	return object
end

function Tab:AddSlider(config: SliderConfig)
	local text = config.Text or "Slider"
	local callback = config.Callback
	local min = config.Min or 0
	local max = config.Max or 100
	local suffix = config.Suffix or ""
	local updateOnRelease = config.UpdateOnRelease == true

	local holder = create("Frame", {
		Name = "Slider_" .. text,
		Size = UDim2.new(1, 0, 0, 55),
		BackgroundColor3 = Theme.Colors.Component,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})
	addCorner(holder, Theme.Sizes.ControlCorner)

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -100, 0, 16),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 13,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = holder,
	})

	local valueLabel = create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.new(0, 88, 0, 16),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = "0",
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextScaled = false,
		Parent = holder,
	})

	local trackHolder = create("Frame", {
		Name = "TrackHolder",
		Position = UDim2.new(0, 12, 0, 32),
		Size = UDim2.new(1, -24, 0, 14),
		BackgroundTransparency = 1,
		Parent = holder,
	})

	local track = create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Theme.Colors.Track,
		BorderSizePixel = 0,
		Parent = trackHolder,
	})
	addCorner(track, 3)

	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Colors.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	addCorner(fill, 3)

	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = Theme.Colors.Text,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	addCorner(knob, 6)

	local object: any = {}
	object.Type = "Slider"
	object.Instance = holder
	object.Min = min
	object.Max = max

	local dragging = false

	local function format(value: number): string
		return tostring(math.round(value)) .. suffix
	end

	local function apply(value: number, fire: boolean?)
		local clamped = math.clamp(value, min, max)
		local alpha = 0
		if max - min > 0 then
			alpha = (clamped - min) / (max - min)
		end

		object.Value = clamped
		valueLabel.Text = format(clamped)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)

		if fire ~= false and callback then
			callback(clamped)
		end
		refreshDependents(object)
	end

	function object:Set(value: number, fire: boolean?)
		apply(value, fire)
	end

	function object:Get(): number
		return self.Value
	end

	local function updateFromInput(input: InputObject)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local relative = (input.Position.X - track.AbsolutePosition.X) / width
		relative = math.clamp(relative, 0, 1)
		apply(min + (max - min) * relative, not updateOnRelease)
	end

	trackHolder.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging and updateOnRelease and callback then
				callback(object.Value)
			end
			dragging = false
		end
	end)

	addPaidBadge(label, config)

	holder.MouseEnter:Connect(function()
		Effects.tween(holder, Theme.Anim.Fast, { BackgroundTransparency = 0.9 })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
	end)
	holder.MouseLeave:Connect(function()
		Effects.tween(holder, Theme.Anim.Fast, { BackgroundTransparency = 1 })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
	end)

	local default = config.Default
	if default == nil then
		default = min
	end
	apply(default, false)
	self.Flags[text] = object
	if config.DependsOn then
		bindDepends(config.DependsOn, holder)
	end

	return object
end

function Tab:AddDropdown(config: DropdownConfig)
	local text = config.Text or "Dropdown"
	local callback = config.Callback
	local options = config.Options or {}

	local root = create("Frame", {
		Name = "Dropdown_" .. text,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})
	addList(root, 4, Enum.HorizontalAlignment.Center)

	local card = create("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 55),
		BackgroundColor3 = Theme.Colors.Component,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Parent = root,
	})

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 14,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		Parent = card,
	})

	local button = create("TextButton", {
		Name = "Button",
		Position = UDim2.new(0, 12, 0, 32),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundColor3 = Theme.Colors.DropdownBar,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = card,
	})
	addCorner(button, 6)

	local selectedLabel = create("TextLabel", {
		Name = "Selected",
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = "",
		TextSize = 13,
		TextColor3 = Theme.Colors.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		Parent = button,
	})

	local optionsFrame = create("ScrollingFrame", {
		Name = "Options",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Theme.Colors.ComponentDeep,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Colors.Stroke,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		LayoutOrder = 1,
		Parent = root,
	})
	addCorner(optionsFrame, Theme.Sizes.ControlCorner)
	addStroke(optionsFrame, Theme.Colors.Stroke, 1, 0.5)
	addPadding(optionsFrame, 4, 4, 4, 4)
	addList(optionsFrame, 2, Enum.HorizontalAlignment.Center)

	local object: any = {}
	object.Type = "Dropdown"
	object.Instance = root
	object.Root = root
	object.Options = table.clone(options)
	object.Value = config.Default or options[1] or ""
	object._open = false
	object.Interactable = true
	object._rows = {}

	local function setOpen(state: boolean)
		if state then
			-- exclusive: collapse any other open dropdown first
			if currentOpenDropdown and currentOpenDropdown ~= object and currentOpenDropdown.Close then
				currentOpenDropdown:Close()
			end
			currentOpenDropdown = object
		elseif currentOpenDropdown == object then
			currentOpenDropdown = nil
		end

		object._open = state
		optionsFrame.Visible = state

		local rows = #object.Options
		local height = math.min(rows * 26 + 10, 140)
		optionsFrame.Size = state and UDim2.new(1, 0, 0, height) or UDim2.new(1, 0, 0, 0)
	end

	local function renderOptions()
		for _, row in ipairs(object._rows) do
			row:Destroy()
		end
		table.clear(object._rows)

		for index, option in ipairs(object.Options) do
			local row = create("TextButton", {
				Name = "Option_" .. option,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Theme.Colors.HoverTint,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Parent = optionsFrame,
			})
			addCorner(row, 4)

			if config.Favorites then
				local isFav = config.GetFavorite and config.GetFavorite(option) or false
				local MUTED = Color3.fromRGB(130, 130, 130)
				local MUTED_HOVER = Color3.fromRGB(170, 170, 170)
				local star = create("TextButton", {
					Name = "FavStar",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.new(0, 20, 0, 20),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Font = Theme.Fonts.Body,
					Text = "\u{2605}",
					TextSize = 18,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextColor3 = isFav and Theme.Colors.Accent or MUTED,
					ZIndex = 3,
					Parent = row,
				})
				star:SetAttribute("Favorited", isFav)
				star:SetAttribute("IsFav", isFav)
				star.MouseEnter:Connect(function()
					if star:GetAttribute("Favorited") then
						star.TextColor3 = Theme.Colors.Accent
					else
						star.TextColor3 = MUTED_HOVER
					end
				end)
				star.MouseLeave:Connect(function()
					star.TextColor3 = star:GetAttribute("Favorited") and Theme.Colors.Accent or MUTED
				end)
				star.MouseButton1Click:Connect(function()
					local nowFav = not star:GetAttribute("Favorited")
					-- update state attribute FIRST so the click is registered before any re-render
					star:SetAttribute("Favorited", nowFav)
					star:SetAttribute("IsFav", nowFav)
					star.TextColor3 = nowFav and Theme.Colors.Accent or MUTED
					-- defer the data update + list re-sort so the UI event loop completes first
					task.defer(function()
						if config.SetFavorite then
							config.SetFavorite(option)
						end
						local newOpts = config.GetOptions and config.GetOptions() or object.Options
						object:Refresh(newOpts)
						setOpen(true)
					end)
				end)
			end

			local rowLabel = create("TextLabel", {
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, config.Favorites and -30 or -16, 1, 0),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Body,
				Text = option,
				TextSize = 12,
				TextColor3 = option == object.Value and Theme.Colors.Accent or Theme.Colors.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			row.MouseEnter:Connect(function()
				Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 0.9 })
				Effects.tween(rowLabel, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
			end)

			row.MouseLeave:Connect(function()
				Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 1 })
				Effects.tween(rowLabel, Theme.Anim.Fast, {
					TextColor3 = option == object.Value and Theme.Colors.Accent or Theme.Colors.TextMuted,
				})
			end)

			row.MouseButton1Click:Connect(function()
				object:Set(option)
				setOpen(false)
			end)

			table.insert(object._rows, row)
		end
	end

	function object:Set(value: string, fire: boolean?)
		self.Value = value
		selectedLabel.Text = value

		for _, row in ipairs(self._rows) do
			local rowLabel = row:FindFirstChildOfClass("TextLabel")
			if rowLabel then
				rowLabel.TextColor3 = (rowLabel.Text == value) and Theme.Colors.Accent or Theme.Colors.TextMuted
			end
		end

		if fire ~= false and callback then
			callback(value)
		end
		refreshDependents(self)
	end

	function object:Get(): string
		return self.Value
	end

	function object:IsOpen(): boolean
		return self._open
	end

	function object:Close()
		setOpen(false)
	end

	function object:SetInteractable(state: boolean)
		self.Interactable = state
		button.Active = state
		button.AutoButtonColor = false
		button.BackgroundTransparency = state and 0 or 0.5
		button.TextTransparency = state and 0 or 0.5
		selectedLabel.TextTransparency = state and 0 or 0.5
		if not state then
			setOpen(false)
		end
	end

	function object:IsInteractable(): boolean
		return self.Interactable ~= false
	end

	function object:Refresh(newOptions: { string })
		self.Options = table.clone(newOptions)
		renderOptions()
		if self._open then
			local rows = #self.Options
			local height = math.min(rows * 26 + 10, 140)
			optionsFrame.Size = UDim2.new(1, 0, 0, height)
		end
	end

	addPaidBadge(label, config)

	button.MouseButton1Click:Connect(function()
		if object.Interactable == false then
			return
		end
		setOpen(not object._open)
	end)

	button.MouseEnter:Connect(function()
		Effects.tween(button, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.ComponentDeep })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
	end)

	button.MouseLeave:Connect(function()
		Effects.tween(button, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.DropdownBar })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
	end)

	renderOptions()
	object:Set(object.Value, false)

	table.insert(openDropdowns, object)
	self.Flags[text] = object
	if config.DependsOn then
		bindDepends(config.DependsOn, root)
	end

	return object
end

function Tab:AddMultiDropdown(config: MultiDropdownConfig)
	local text = config.Title or "Multi"
	local callback = config.Callback
	local options = config.Options or {}

	local selected: {[string]: boolean} = {}
	local selectedOrder: { string } = {}
	if config.Default then
		for _, item in ipairs(config.Default) do
			if not selected[item] then
				selected[item] = true
				table.insert(selectedOrder, item)
			end
		end
	end

	local root = create("Frame", {
		Name = "MultiDropdown_" .. text,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})
	addList(root, 4, Enum.HorizontalAlignment.Center)

	local card = create("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 55),
		BackgroundColor3 = Theme.Colors.Component,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Parent = root,
	})

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 14,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		Parent = card,
	})

	local button = create("TextButton", {
		Name = "Button",
		Position = UDim2.new(0, 12, 0, 32),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundColor3 = Theme.Colors.DropdownBar,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = card,
	})
	addCorner(button, 6)

	local selectedLabel = create("TextLabel", {
		Name = "Selected",
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = "",
		TextSize = 13,
		TextColor3 = Theme.Colors.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		Parent = button,
	})

	local optionsFrame = create("ScrollingFrame", {
		Name = "Options",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Theme.Colors.ComponentDeep,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Colors.Stroke,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		LayoutOrder = 1,
		Parent = root,
	})
	addCorner(optionsFrame, Theme.Sizes.ControlCorner)
	addStroke(optionsFrame, Theme.Colors.Stroke, 1, 0.5)
	addPadding(optionsFrame, 4, 4, 4, 4)
	addList(optionsFrame, 2, Enum.HorizontalAlignment.Center)

	local object: any = {}
	object.Type = "MultiDropdown"
	object.Instance = root
	object.Root = root
	object.Options = table.clone(options)
	object.Selected = selected
	object._open = false
	object._rows = {}

	local function currentText(): string
		local chosen = selectedOrder
		if #chosen == 0 then
			return "None"
		elseif #chosen == 1 then
			return chosen[1]
		elseif #chosen == 2 then
			return chosen[1] .. ", " .. chosen[2]
		else
			return chosen[1] .. ", " .. chosen[2] .. "..."
		end
	end

	local function notify()
		selectedLabel.Text = currentText()
		if callback then
			callback(table.clone(selectedOrder))
		end
	end

	local function setOpen(state: boolean)
		if state then
			-- exclusive: collapse any other open dropdown first
			if currentOpenDropdown and currentOpenDropdown ~= object and currentOpenDropdown.Close then
				currentOpenDropdown:Close()
			end
			currentOpenDropdown = object
		elseif currentOpenDropdown == object then
			currentOpenDropdown = nil
		end

		object._open = state
		optionsFrame.Visible = state
		local rows = #object.Options
		local height = math.min(rows * 26 + 10, 140)
		optionsFrame.Size = state and UDim2.new(1, 0, 0, height) or UDim2.new(1, 0, 0, 0)
	end

	local function renderOptions()
		for _, row in ipairs(object._rows) do
			row:Destroy()
		end
		table.clear(object._rows)

		for index, option in ipairs(object.Options) do
			local row = create("TextButton", {
				Name = "Option_" .. option,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Theme.Colors.HoverTint,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Parent = optionsFrame,
			})
			addCorner(row, 4)

			local rowLabel = create("TextLabel", {
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Body,
				Text = option,
				TextSize = 13,
				TextColor3 = selected[option] and Theme.Colors.Accent or Theme.Colors.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextScaled = false,
				Parent = row,
			})

			row.MouseEnter:Connect(function()
				Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 0.9 })
			end)
			row.MouseLeave:Connect(function()
				Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 1 })
			end)

			row.MouseButton1Click:Connect(function()
				if selected[option] then
					selected[option] = nil
					for i, name in ipairs(selectedOrder) do
						if name == option then
							table.remove(selectedOrder, i)
							break
						end
					end
					rowLabel.TextColor3 = Theme.Colors.TextMuted
				else
					selected[option] = true
					table.insert(selectedOrder, option)
					rowLabel.TextColor3 = Theme.Colors.Accent
				end
				notify()
			end)

			table.insert(object._rows, row)
		end
	end

	function object:Set(value: { string }, fire: boolean?)
		table.clear(selected)
		table.clear(selectedOrder)
		for _, item in ipairs(value) do
			if not selected[item] then
				selected[item] = true
				table.insert(selectedOrder, item)
			end
		end
		selectedLabel.Text = currentText()
		if fire ~= false and callback then
			callback(table.clone(selectedOrder))
		end
		refreshDependents(self)
	end

	function object:Get(): { string }
		return table.clone(selectedOrder)
	end

	function object:IsOpen(): boolean
		return self._open
	end

	function object:Close()
		setOpen(false)
	end

	button.MouseButton1Click:Connect(function()
		setOpen(not object._open)
	end)

	button.MouseEnter:Connect(function()
		Effects.tween(button, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.ComponentDeep })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
	end)
	button.MouseLeave:Connect(function()
		Effects.tween(button, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.DropdownBar })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
	end)

	renderOptions()
	selectedLabel.Text = currentText()

	table.insert(openDropdowns, object)
	self.Flags[text] = object
	if config.DependsOn then
		bindDepends(config.DependsOn, root)
	end

	return object
end

function Tab:AddTextInput(config: TextInputConfig)
	local text = config.Text or "Input"
	local callback = config.Callback

	local row = create("Frame", {
		Name = "Input_" .. text,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 12,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local box = create("TextBox", {
		Name = "Box",
		Position = UDim2.new(1, -130, 0, 0),
		Size = UDim2.new(0, 130, 1, 0),
		BackgroundColor3 = Theme.Colors.DropdownBar,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Font = Theme.Fonts.Mono,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "Enter text...",
		PlaceholderColor3 = Theme.Colors.TextDim,
		TextSize = 11,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Parent = row,
	})
	addCorner(box, 6)
	addStroke(box, Theme.Colors.Stroke, 1, 0.5)
	addPadding(box, 0, 8, 0, 8)
	addPaidBadge(label, config)

	local object: any = {}
	object.Type = "TextInput"
	object.Instance = row
	object.Value = config.Default or ""

	local placeholder = config.Placeholder or "Enter text..."
	local clearOnFocus = config.PlaceholderClearOnFocus == true

	box.Focused:Connect(function()
		Effects.tween(box, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.ComponentDeep })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
		if clearOnFocus then
			box.PlaceholderText = ""
		end
	end)

	box.FocusLost:Connect(function()
		Effects.tween(box, Theme.Anim.Fast, { BackgroundColor3 = Theme.Colors.DropdownBar })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
		if clearOnFocus then
			box.PlaceholderText = placeholder
		end
		object.Value = box.Text
		if callback then
			callback(box.Text)
		end
		refreshDependents(object)
	end)

	if config.Live then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			object.Value = box.Text
			if callback then
				callback(box.Text)
			end
			refreshDependents(object)
		end)
	end

	function object:Set(value: string, fire: boolean?)
		self.Value = value
		box.Text = value
		if fire ~= false and callback then
			callback(value)
		end
		refreshDependents(self)
	end

	function object:Get(): string
		return self.Value
	end

	self.Flags[text] = object
	if config.DependsOn then
		bindDepends(config.DependsOn, row)
	end

	return object
end

function Tab:AddKeybind(config: KeybindConfig)
	local text = config.Text or "Keybind"
	local callback = config.Callback

	local row = create("Frame", {
		Name = "Keybind_" .. text,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		Parent = self:_target(),
	})

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -84, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = text,
		TextSize = 12,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local keyButton = create("TextButton", {
		Name = "Key",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 72, 0, 16),
		BackgroundColor3 = Theme.Colors.DropdownBar,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Font = Theme.Fonts.Body,
		Text = "[ None ]",
		TextSize = 12,
		TextColor3 = Theme.Colors.TextDim,
		Parent = row,
	})
	addCorner(keyButton, 4)
	addPaidBadge(label, config)

	local object: any = {}
	object.Type = "Keybind"
	object.Instance = row
	object.Value = config.Default

	local function render()
		if object.Value then
			keyButton.Text = "[ " .. object.Value.Name .. " ]"
			keyButton.TextColor3 = Theme.Colors.Accent
		else
			keyButton.Text = "[ None ]"
			keyButton.TextColor3 = Theme.Colors.TextDim
		end
	end

	local listening = false

	local function stopListening()
		listening = false
		activeKeyCapture = nil
		render()
	end

	keyButton.MouseButton1Click:Connect(function()
		if listening then
			stopListening()
			return
		end

		listening = true
		keyButton.Text = "[ Press Key... ]"
		keyButton.TextColor3 = Theme.Colors.TextMuted

		activeKeyCapture = function(key: Enum.KeyCode)
			if key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
				object.Value = nil
			else
				object.Value = key
			end
			stopListening()
			if callback then
				callback(object.Value)
			end
		end
	end)

	row.MouseEnter:Connect(function()
		Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 0.92 })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.Text })
	end)

	row.MouseLeave:Connect(function()
		Effects.tween(row, Theme.Anim.Fast, { BackgroundTransparency = 1 })
		Effects.tween(label, Theme.Anim.Fast, { TextColor3 = Theme.Colors.TextMuted })
	end)

	function object:Set(key: Enum.KeyCode?, fire: boolean?)
		self.Value = key
		render()
		if fire ~= false and callback then
			callback(key)
		end
		refreshDependents(self)
	end

	function object:Get(): Enum.KeyCode?
		return self.Value
	end

	render()
	self.Flags[text] = object
	if config.DependsOn then
		bindDepends(config.DependsOn, row)
	end

	return object
end

-- =========================================================================================
--  11. LIBRARY - NOTIFICATIONS
-- =========================================================================================

function Library:Notify(config: NotifyConfig)
	-- 40% lifetime: toast + progress line drain 2.5x faster
	local duration = (config.Duration or 4) * 0.4
	local toastType = config.Type or config.Title
	local library = self

	local record = self._activeToasts[toastType]

	-- ===== IN-PLACE REFRESH =====
	-- Same type already on screen: never destroy or re-create the frame. Update the
	-- text in place, pulse the card + content, and reset the auto-close countdown
	-- (and the top progress line) instead of spawning a duplicate.
	if record and record.toast and record.toast.Parent then
		local toast = record.toast
		record.token += 1
		local myToken = record.token

		local card = toast:FindFirstChild("Card")
		if card then
			local title = card:FindFirstChild("Title")
			local content = card:FindFirstChild("Content")
			if content then
				-- fast fade out -> swap string -> fast fade in (~0.09s each)
				local fadeOut = Effects.tween(content, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 1,
				})
				fadeOut.Completed:Once(function()
					if not content.Parent then
						return
					end
					if title then
						title.Text = config.Title
					end
					content.Text = config.Content
					Effects.tween(content, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						TextTransparency = 0,
					})
				end)
			elseif title then
				title.Text = config.Title
			end
			local scale = card:FindFirstChild("ToastPulse")
			if not scale then
				scale = create("UIScale", { Name = "ToastPulse", Scale = 1, Parent = card })
			end
			scale.Scale = 1.04
			Effects.tween(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
		end

		-- reset the top progress line back to 100%
		if record.progress and record.progress.Parent then
			if record.progressTween then
				record.progressTween:Cancel()
			end
			record.progress.Size = UDim2.new(0, 0, 1, 0)
			record.progressTween = Effects.tween(
				record.progress,
				TweenInfo.new(duration, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(1, 0, 1, 0) }
			)
		end

		task.delay(duration, function()
			if record.token ~= myToken then
				return
			end
			if not toast.Parent then
				return
			end
			library._activeToasts[toastType] = nil
			local outCard = toast:FindFirstChild("Card")
			if outCard then
				Effects.tween(outCard, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.new(1, 0, 0, 0),
				})
			end
			local out = Effects.tween(toast, Theme.Anim.Normal, { GroupTransparency = 1 })
			out.Completed:Once(function()
				toast:Destroy()
			end)
		end)

		return toast
	end

	-- toast is the clipping container; the sliding "Card" holds the visuals
	local toast = create("CanvasGroup", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		LayoutOrder = self._notifyOrder,
		Parent = self.NotificationHolder,
	})

	local card = create("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Theme.Colors.Component,
		BackgroundTransparency = library.Acrylic and 0.35 or 0,
		BorderSizePixel = 0,
		Parent = toast,
	})
	addCorner(card, Theme.Sizes.ControlCorner)
	addStroke(card, Theme.Colors.Stroke, 1, 0.4)
	addPadding(card, 10, 12, 10, 12)
	addList(card, 4, Enum.HorizontalAlignment.Left)

	self._notifyOrder += 1

	local accent = create("Frame", {
		Name = "Accent",
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Theme.Colors.Accent,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Parent = card,
	})
	addCorner(accent, 1)

	local progress = create("Frame", {
		Name = "Progress",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Colors.Background,
		BorderSizePixel = 0,
		Parent = accent,
	})

	create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Header,
		Text = config.Title,
		TextSize = 13,
		TextColor3 = Theme.Colors.Text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1,
		Parent = card,
	})

	create("TextLabel", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		Text = config.Content,
		TextSize = 12,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = 2,
		Parent = card,
	})

	local progressTween = Effects.tween(
		progress,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(1, 0, 1, 0) }
	)

	self._activeToasts[toastType] = {
		toast = toast,
		token = 1,
		progress = progress,
		progressTween = progressTween,
	}

	-- slide in from the right + fade in
	Effects.tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	})
	Effects.tween(toast, Theme.Anim.Normal, { GroupTransparency = 0 })

	task.delay(duration, function()
		local rec = library._activeToasts[toastType]
		if not rec or rec.toast ~= toast or rec.token ~= 1 then
			return
		end
		if not toast.Parent then
			return
		end
		library._activeToasts[toastType] = nil
		local outCard = toast:FindFirstChild("Card")
		if outCard then
			Effects.tween(outCard, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 0, 0, 0),
			})
		end
		local out = Effects.tween(toast, Theme.Anim.Normal, { GroupTransparency = 1 })
		out.Completed:Once(function()
			toast:Destroy()
		end)
	end)

	return toast
end

-- =========================================================================================
--  12. MODULE EXPORT
-- =========================================================================================

local Sakka = {
	new = Library.new,
	Theme = Theme,
	Effects = Effects,
	Version = "1.0.0",
}

return Sakka
