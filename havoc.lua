local CoreGui = game:GetService("CoreGui")
local camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local FILE_NAME = "CryzsnConfig.json"

------------------------------------------------
-- GUI SETUP
------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name="CryzsnSystem"
screenGui.ResetOnSpawn=false

pcall(function()
	screenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
end)

if not screenGui.Parent then
	screenGui.Parent = player:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Size=UDim2.new(0,160,0,220)
mainFrame.Position=UDim2.new(.5,-80,.3,0)
mainFrame.BackgroundColor3=Color3.fromRGB(0,0,0)
mainFrame.Active=true
mainFrame.Draggable=true
mainFrame.Parent=screenGui

Instance.new("UICorner",mainFrame).CornerRadius=UDim.new(0,10)

local stroke=Instance.new("UIStroke",mainFrame)
stroke.Color=Color3.fromRGB(160,32,240)

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,0,0,35)
title.BackgroundTransparency=1
title.Text="HAVOC DUEL HELPER"
title.Font=Enum.Font.LuckiestGuy
title.TextColor3=Color3.fromRGB(190,100,255)
title.TextSize=14
title.Parent=mainFrame

------------------------------------------------
-- ❄️ GUI SNOW (VISIBLE ONLY + DEPTH)
------------------------------------------------

local snowFolder = Instance.new("Folder")
snowFolder.Name = "GuiSnow"
snowFolder.Parent = mainFrame

local snowflakes = {}

-- Depth layers
local LAYERS = {
	{SizeMin = 6, SizeMax = 8, SpeedMin = 8,  SpeedMax = 12},  -- back layer (big slow)
	{SizeMin = 3, SizeMax = 5, SpeedMin = 18, SpeedMax = 28}   -- front layer (small fast)
}

local function createSnow(layer)

	local size = math.random(layer.SizeMin, layer.SizeMax)

	local snow = Instance.new("Frame")
	snow.Size = UDim2.new(0,size,0,size)
	snow.BackgroundColor3 = Color3.new(1,1,1)
	snow.BorderSizePixel = 0
	snow.BackgroundTransparency = 0.1
	snow.ZIndex = layer == LAYERS[1] and 0 or 2

	Instance.new("UICorner", snow).CornerRadius = UDim.new(1,0)

	local glow = Instance.new("UIStroke")
	glow.Thickness = layer == LAYERS[1] and 1 or 2
	glow.Transparency = 0.4
	glow.Color = Color3.fromRGB(220,220,255)
	glow.Parent = snow

	snow.Position = UDim2.new(math.random(),0,-0.1,0)
	snow.Parent = snowFolder

	table.insert(snowflakes,{
		Obj = snow,
		Speed = math.random(layer.SpeedMin, layer.SpeedMax)/100
	})
end

local function spawnSnow()

	for _,v in ipairs(snowflakes) do
		if v.Obj then
			v.Obj:Destroy()
		end
	end
	table.clear(snowflakes)

	for _,layer in ipairs(LAYERS) do
		for i = 1,15 do
			createSnow(layer)
		end
	end
end

local function clearSnow()
	for _,v in ipairs(snowflakes) do
		if v.Obj then
			v.Obj:Destroy()
		end
	end
	table.clear(snowflakes)
end

RunService.Heartbeat:Connect(function(dt)

	if not mainFrame.Visible then return end

	for _,data in ipairs(snowflakes) do

		local snow = data.Obj
		if not snow then continue end

		local pos = snow.Position

		snow.Position = UDim2.new(
			pos.X.Scale,
			0,
			pos.Y.Scale + (data.Speed * dt),
			0
		)

		if snow.Position.Y.Scale > 1.1 then
			snow.Position = UDim2.new(math.random(),0,-0.1,0)
		end
	end
end)
------------------------------------------------
-- BUTTON CREATION
------------------------------------------------

local function createBtn(text,pos,save)

	local b=Instance.new("TextButton")
	b.Size=UDim2.new(.85,0,0,28)
	b.Position=pos
	b.BackgroundColor3=save and Color3.fromRGB(0,80,0)
	or Color3.fromRGB(45,0,70)

	b.Text=text
	b.Font=Enum.Font.LuckiestGuy
	b.TextColor3=Color3.new(1,1,1)
	b.TextSize=13
	b.Parent=mainFrame

	Instance.new("UICorner",b)

	return b
end

local fovBtn=createBtn("FOV: OFF",UDim2.new(.075,0,.18,0))
local galaxyBtn=createBtn("GALAXY MODE: OFF",UDim2.new(.075,0,.33,0))
local antiBatBtn=createBtn("ANTI BAT: OFF",UDim2.new(.075,0,.48,0))
local antiFlingBtn=createBtn("ANTI-FLING: OFF",UDim2.new(.075,0,.63,0))
local saveBtn=createBtn("SAVE CONFIG",UDim2.new(.075,0,.82,0),true)

------------------------------------------------
-- STATES
------------------------------------------------

local fovOn=false
local galaxyOn=false
local antiBatOn=false
local antiFlingOn=false

local detectDistance=15

local defBrightness=Lighting.Brightness
local defClock=Lighting.ClockTime
local defAmbient=Lighting.OutdoorAmbient

------------------------------------------------
-- GALAXY MODE
------------------------------------------------

local function updateGalaxy()

	galaxyBtn.Text=galaxyOn and "GALAXY MODE: ON" or "GALAXY MODE: OFF"

	if galaxyOn then

		local sky=Instance.new("Sky")
		sky.Name="GalaxySky"

		sky.SkyboxBk="rbxassetid://159454299"
		sky.SkyboxDn="rbxassetid://159454296"
		sky.SkyboxFt="rbxassetid://159454293"
		sky.SkyboxLf="rbxassetid://159454286"
		sky.SkyboxRt="rbxassetid://159454289"
		sky.SkyboxUp="rbxassetid://159454291"

		sky.Parent=Lighting

		Lighting.Brightness=0
		Lighting.ClockTime=0
		Lighting.ExposureCompensation=-2
		Lighting.OutdoorAmbient=Color3.new()

	else

		local s=Lighting:FindFirstChild("GalaxySky")
		if s then s:Destroy() end

		Lighting.Brightness=defBrightness
		Lighting.ClockTime=defClock
		Lighting.OutdoorAmbient=defAmbient
	end
end

------------------------------------------------
-- BUTTONS
------------------------------------------------

fovBtn.MouseButton1Click:Connect(function()

	fovOn=not fovOn
	camera.FieldOfView=fovOn and 100 or 70

	fovBtn.Text=fovOn and "FOV: ON" or "FOV: OFF"

end)

galaxyBtn.MouseButton1Click:Connect(function()

	galaxyOn=not galaxyOn
	updateGalaxy()

end)

antiBatBtn.MouseButton1Click:Connect(function()

	antiBatOn=not antiBatOn
	antiBatBtn.Text=antiBatOn and "ANTI BAT: ON" or "ANTI BAT: OFF"

end)

antiFlingBtn.MouseButton1Click:Connect(function()

	antiFlingOn=not antiFlingOn
	antiFlingBtn.Text=antiFlingOn and "ANTI-FLING: ON" or "ANTI-FLING: OFF"

end)

------------------------------------------------
-- ANTI FLING
------------------------------------------------

RunService.Stepped:Connect(function()

	if not antiFlingOn then return end

	local char=player.Character
	if not char then return end

	for _,v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide=false
		end
	end
end)

------------------------------------------------
-- TOGGLE KEY (K)
------------------------------------------------

local guiVisible = true

spawnSnow() -- start snow when GUI loads

UserInputService.InputBegan:Connect(function(input,processed)

	if processed then return end

	if input.KeyCode == Enum.KeyCode.K then

		guiVisible = not guiVisible
		mainFrame.Visible = guiVisible

		if guiVisible then
			spawnSnow()
		else
			clearSnow()
		end

	end
end)
