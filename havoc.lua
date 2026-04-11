-- [[ DEOBFUSCATED BY @Bhmatrades ]] --

-- // [1] SERVICES //
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGuiColors")

local LocalPlayer = Players.LocalPlayer

-- // [2] CONFIGURATION (EDITABLE) //
local CONFIG = {
	Gui = {
		Name = "AngelicHub",
		DisplayOrder = 10,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
	},

	Colors = {
	MainBackground = Color3.fromRGB(245, 245, 255),   -- soft white
	TitleBar = Color3.fromRGB(255, 255, 255),         -- pure white
	SectionBackground = Color3.fromRGB(235, 235, 245),-- light panel

	Accent = Color3.fromRGB(255, 215, 120),           -- gold glow

	Text = Color3.fromRGB(60, 60, 80),                -- soft dark text
	SecondaryText = Color3.fromRGB(140, 140, 170),    -- faded text
},

	Defaults = {
		NormalSpeed = 60,
		CarrySpeed = 30,
		StealRadius = 20,
		StealDuration = 0.25,
		FloatHeight = 9.5,
	},

	Keybinds = {
		Mode = Enum.KeyCode.Q,
		AutoBat = Enum.KeyCode.E,
		AutoLeft = Enum.KeyCode.Z,
		AutoRight = Enum.KeyCode.C,
		DropBrainrot = Enum.KeyCode.X,
		TPDown = Enum.KeyCode.F,
		Float = Enum.KeyCode.J,
		HideGui = Enum.KeyCode.LeftControl,
	},
}

-- // [3] OBJECT REFERENCES //
local ScreenGui
local MainFrame
local TitleBar
local TitleLabel
local MinimizeButton
local ScrollingFrame
local SpeedLabel

local Toggles = {}
local CurrentSpeedValue = CONFIG.Defaults.NormalSpeed
local IsSpeedEnabled = false
local IsFloatEnabled = false
local FloatHeight = CONFIG.Defaults.FloatHeight

-- // [4] UTILITY FUNCTIONS //
local function getCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
	local char = getCharacter()
	return char:WaitForChild("Humanoid")
end

local function getRootPart()
	local char = getCharacter()
	return char:WaitForChild("HumanoidRootPart")
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or CONFIG.Colors.Accent
	stroke.Thickness = thickness or 1.5
	stroke.Transparency = 0.2
	stroke.Parent = parent
	return stroke
end

local function updateSpeedLabel()
	local root = getRootPart()
	local speed = root.AssemblyLinearVelocity.Magnitude
	SpeedLabel.Text = "Speed: " .. string.format("%.1f", speed)
end

-- // [5] GUI HANDLING (CLEAN ORIGINAL STRUCTURE) //
local function buildGUI()
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = CONFIG.Gui.Name
	ScreenGui.ResetOnSpawn = CONFIG.Gui.ResetOnSpawn
	ScreenGui.DisplayOrder = CONFIG.Gui.DisplayOrder
	ScreenGui.IgnoreGuiInset = CONFIG.Gui.IgnoreGuiInset
	ScreenGui.Parent = CoreGui

	MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 300, 0, 460)
	MainFrame.Position = UDim2.new(0, 20, 0, 20)
	MainFrame.BackgroundColor3 = CONFIG.Colors.MainBackground
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Active = true
	MainFrame.Draggable = true
	MainFrame.Parent = ScreenGui
	createCorner(MainFrame, 12)

	TitleBar = Instance.new("Frame")
	TitleBar.Size = UDim2.new(1, 0, 0, 44)
	TitleBar.BackgroundColor3 = CONFIG.Colors.TitleBar
	TitleBar.BorderSizePixel = 0
	TitleBar.Parent = MainFrame
	createCorner(TitleBar, 6)

	TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -50, 1, 0)
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = "angelic HUB"
	TitleLabel.TextColor3 = CONFIG.Colors.Accent
	TitleLabel.Font = Enum.Font.GothamBlack
	TitleLabel.TextSize = 14
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = TitleBar

	MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Size = UDim2.new(0, 28, 0, 28)
	MinimizeButton.Position = UDim2.new(1, -34, 0.5, -14)
	MinimizeButton.BackgroundColor3 = Color3.fromRGB(18, 8, 10)
	MinimizeButton.Text = "-"
	MinimizeButton.TextColor3 = Color3.fromRGB(120, 20, 30)
	MinimizeButton.Font = Enum.Font.GothamBold
	MinimizeButton.TextSize = 22
	MinimizeButton.Parent = TitleBar
	createCorner(MinimizeButton, 6)

	ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Size = UDim2.new(1, 0, 1, -44)
	ScrollingFrame.Position = UDim2.new(0, 0, 0, 44)
	ScrollingFrame.BackgroundTransparency = 1
	ScrollingFrame.BorderSizePixel = 0
	ScrollingFrame.ScrollBarThickness = 2
	ScrollingFrame.ScrollBarImageColor3 = CONFIG.Colors.Accent
	ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollingFrame.Parent = MainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = ScrollingFrame

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingLeft = UDim.new(0, 7)
	scrollPadding.PaddingRight = UDim.new(0, 7)
	scrollPadding.PaddingTop = UDim.new(0, 7)
	scrollPadding.PaddingBottom = UDim.new(0, 10)
	scrollPadding.Parent = ScrollingFrame

	local speedContainer = Instance.new("Frame")
	speedContainer.Size = UDim2.new(1, -18, 0, 32)
	speedContainer.BackgroundColor3 = CONFIG.Colors.SectionBackground
	speedContainer.LayoutOrder = 0
	speedContainer.Parent = ScrollingFrame
	createCorner(speedContainer, 7)
	createStroke(speedContainer, Color3.fromRGB(22, 22, 28))

	SpeedLabel = Instance.new("TextLabel")
	SpeedLabel.Size = UDim2.new(1, -8, 1, 0)
	SpeedLabel.Position = UDim2.new(0, 8, 0, 0)
	SpeedLabel.BackgroundTransparency = 1
	SpeedLabel.Text = "Speed: 0.0"
	SpeedLabel.TextColor3 = CONFIG.Colors.Text
	SpeedLabel.Font = Enum.Font.GothamBold
	SpeedLabel.TextSize = 14
	SpeedLabel.Parent = speedContainer

	local featuresList = {
		{section = "SPEED", order = 1, name = "Normal Speed", type = "toggle", default = false, valueBox = true, defaultValue = CONFIG.Defaults.NormalSpeed},
		{section = "SPEED", order = 2, name = "Carry Speed", type = "toggle", default = false, valueBox = true, defaultValue = CONFIG.Defaults.CarrySpeed},
		{section = "SPEED", order = 3, name = "Mode", type = "toggle", default = false, keybind = CONFIG.Keybinds.Mode},

		{section = "COMBAT", order = 7, name = "Auto Bat", type = "toggle", default = false, keybind = CONFIG.Keybinds.AutoBat},

		{section = "STEAL", order = 10, name = "Radius", type = "value", defaultValue = CONFIG.Defaults.StealRadius},
		{section = "STEAL", order = 11, name = "Auto Steal", type = "toggle", default = false},
		{section = "STEAL", order = 12, name = "Steal Duration", type = "value", defaultValue = CONFIG.Defaults.StealDuration},

		{section = "MISC", order = 13, name = "Infinite Jump", type = "toggle", default = false},
		{section = "MISC", order = 14, name = "Anti Ragdoll", type = "toggle", default = false},
		{section = "MISC", order = 15, name = "Medusa Counter", type = "toggle", default = false},
		{section = "MISC", order = 16, name = "Unwalk", type = "toggle", default = false},

		{section = "VISUAL", order = 18, name = "Anti Lag", type = "toggle", default = false},
		{section = "VISUAL", order = 19, name = "Remove Accessories", type = "toggle", default = false},

		{section = "MOVEMENT", order = 21, name = "Auto Left", type = "toggle", default = false, keybind = CONFIG.Keybinds.AutoLeft},
		{section = "MOVEMENT", order = 22, name = "Auto Right", type = "toggle", default = false, keybind = CONFIG.Keybinds.AutoRight},
		{section = "MOVEMENT", order = 23, name = "Drop Brainrot", type = "toggle", default = false, keybind = CONFIG.Keybinds.DropBrainrot},
		{section = "MOVEMENT", order = 24, name = "TP Down", type = "toggle", default = false, keybind = CONFIG.Keybinds.TPDown},
		{section = "MOVEMENT", order = 25, name = "Float Height", type = "value", defaultValue = CONFIG.Defaults.FloatHeight},
		{section = "MOVEMENT", order = 26, name = "Float", type = "toggle", default = false, keybind = CONFIG.Keybinds.Float},

		{section = "INTERFACE", order = 28, name = "Hide / Show Gui", type = "toggle", default = false, keybind = CONFIG.Keybinds.HideGui},
	}

	local currentSectionFrame
	for _, feat in ipairs(featuresList) do
		if not currentSectionFrame or currentSectionFrame.LayoutOrder ~= feat.order then
			currentSectionFrame = Instance.new("Frame")
			currentSectionFrame.Size = UDim2.new(1, -18, 0, 50)
			currentSectionFrame.BackgroundColor3 = CONFIG.Colors.SectionBackground
			currentSectionFrame.BorderSizePixel = 0
			currentSectionFrame.LayoutOrder = feat.order
			currentSectionFrame.Parent = ScrollingFrame
			createCorner(currentSectionFrame, 7)
			createStroke(currentSectionFrame)

			local sectionTitle = Instance.new("TextLabel")
			sectionTitle.Size = UDim2.new(1, -8, 0, 20)
			sectionTitle.Position = UDim2.new(0, 8, 0, 0)
			sectionTitle.BackgroundTransparency = 1
			sectionTitle.Text = feat.section
			sectionTitle.TextColor3 = CONFIG.Colors.Accent
			sectionTitle.Font = Enum.Font.GothamBold
			sectionTitle.TextSize = 11
			sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
			sectionTitle.Parent = currentSectionFrame
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -16, 0, 28)
		row.Position = UDim2.new(0, 8, 0, 22)
		row.BackgroundTransparency = 1
		row.Parent = currentSectionFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.58, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = feat.name
		nameLabel.TextColor3 = CONFIG.Colors.Text
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 11
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		if feat.type == "toggle" then
			local toggleBtn = Instance.new("TextButton")
			toggleBtn.Size = UDim2.new(0, 46, 0, 22)
			toggleBtn.Position = UDim2.new(1, -50, 0.5, -11)
			toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 10)
			toggleBtn.Text = "OFF"
			toggleBtn.TextColor3 = CONFIG.Colors.SecondaryText
			toggleBtn.Font = Enum.Font.GothamBold
			toggleBtn.TextSize = 9
			toggleBtn.Parent = row
			createCorner(toggleBtn, 5)

			Toggles[feat.name] = {enabled = feat.default, control = toggleBtn}

			toggleBtn.MouseButton1Click:Connect(function()
				local data = Toggles[feat.name]
				data.enabled = not data.enabled
				toggleBtn.Text = data.enabled and "ON" or "OFF"
				toggleBtn.TextColor3 = data.enabled and CONFIG.Colors.Accent or CONFIG.Colors.SecondaryText
			end)
		elseif feat.type == "value" then
			local valueBox = Instance.new("TextBox")
			valueBox.Size = UDim2.new(0, 50, 0, 22)
			valueBox.Position = UDim2.new(1, -56, 0.5, -11)
			valueBox.BackgroundColor3 = Color3.fromRGB(39, 39, 54)
			valueBox.Text = tostring(feat.defaultValue)
			valueBox.TextColor3 = CONFIG.Colors.Text
			valueBox.Font = Enum.Font.GothamBold
			valueBox.TextSize = 11
			valueBox.ClearTextOnFocus = false
			valueBox.Parent = row
			createCorner(valueBox, 5)

			valueBox.FocusLost:Connect(function()
				if feat.name == "Float Height" then
					FloatHeight = tonumber(valueBox.Text) or CONFIG.Defaults.FloatHeight
				elseif feat.name == "Normal Speed" then
					CurrentSpeedValue = tonumber(valueBox.Text) or CONFIG.Defaults.NormalSpeed
				end
			end)
		end
	end
end

-- // [6] FUNCTIONALITY //
local function handleFunctionality()
	RunService.Heartbeat:Connect(function()
		updateSpeedLabel()

		if IsSpeedEnabled then
			local root = getRootPart()
			local hum = getHumanoid()
			local moveDir = hum.MoveDirection
			if moveDir.Magnitude > 0 then
				root.AssemblyLinearVelocity = Vector3.new(moveDir.X * CurrentSpeedValue, root.AssemblyLinearVelocity.Y, moveDir.Z * CurrentSpeedValue)
			end
		end

		if IsFloatEnabled then
			local root = getRootPart()
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
			root.CFrame = CFrame.new(root.Position.X, FloatHeight, root.Position.Z) * CFrame.Angles(0, root.CFrame.Rotation.Y, 0)
		end
	end)

	local jumpConnection
	Toggles["Infinite Jump"].control.MouseButton1Click:Connect(function()
		local data = Toggles["Infinite Jump"]
		if data.enabled then
			if jumpConnection then jumpConnection:Disconnect() end
			jumpConnection = UserInputService.JumpRequest:Connect(function()
				getHumanoid():ChangeState(Enum.HumanoidStateType.Jumping)
			end)
		else
			if jumpConnection then
				jumpConnection:Disconnect()
				jumpConnection = nil
			end
		end
	end)

	Toggles["Remove Accessories"].control.MouseButton1Click:Connect(function()
		local data = Toggles["Remove Accessories"]
		if data.enabled then
			local char = getCharacter()
			for _, acc in ipairs(char:GetChildren()) do
				if acc:IsA("Accessory") then acc:Destroy() end
			end
		end
	end)

	Toggles["Anti Ragdoll"].control.MouseButton1Click:Connect(function()
		local data = Toggles["Anti Ragdoll"]
		if data.enabled then
			local hum = getHumanoid()
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == CONFIG.Keybinds.HideGui then
			ScreenGui.Enabled = not ScreenGui.Enabled
		end
	end)

	MinimizeButton.MouseButton1Click:Connect(function()
		ScrollingFrame.Visible = not ScrollingFrame.Visible
	end)

	Toggles["Normal Speed"].control.MouseButton1Click:Connect(function()
		local data = Toggles["Normal Speed"]
		IsSpeedEnabled = data.enabled
		if data.enabled then
			CurrentSpeedValue = CONFIG.Defaults.NormalSpeed
		end
	end)

	Toggles["Float"].control.MouseButton1Click:Connect(function()
		local data = Toggles["Float"]
		IsFloatEnabled = data.enabled
	end)
end

-- // [7] INITIALIZATION //
local function init()
	buildGUI()
	handleFunctionality()
	print('angelic Hub Loaded')
end

init()
