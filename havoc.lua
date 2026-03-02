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
-- ❄️ GLOWING SNOWFLAKES
------------------------------------------------

local snowFolder=Instance.new("Folder",screenGui)
snowFolder.Name="Snowflakes"

local snowflakes={}

local function createSnow()

	local size=math.random(3,7)

	local snow=Instance.new("Frame")
	snow.Size=UDim2.new(0,size,0,size)
	snow.BackgroundColor3=Color3.new(1,1,1)
	snow.BorderSizePixel=0
	snow.BackgroundTransparency=.05

	Instance.new("UICorner",snow).CornerRadius=UDim.new(1,0)

	local glow=Instance.new("UIStroke")
	glow.Thickness=2
	glow.Transparency=.4
	glow.Color=Color3.fromRGB(220,220,255)
	glow.Parent=snow

	snow.Position=UDim2.new(math.random(),0,-.1,0)
	snow.ZIndex=0
	snow.Parent=snowFolder

	table.insert(snowflakes,{
		Obj=snow,
		Speed=math.random(8,16)/100
	})
end

for i=1,55 do
	createSnow()
end

RunService.Heartbeat:Connect(function(dt)

	for _,data in ipairs(snowflakes) do

		local snow=data.Obj
		local pos=snow.Position

		snow.Position=UDim2.new(
			pos.X.Scale,
			0,
			pos.Y.Scale+(data.Speed*dt),
			0
		)

		if snow.Position.Y.Scale>1.1 then
			snow.Position=UDim2.new(math.random(),0,-.1,0)
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

local guiVisible=true

UserInputService.InputBegan:Connect(function(input,processed)

	if processed then return end

	if input.KeyCode==Enum.KeyCode.K then

		guiVisible=not guiVisible
		mainFrame.Visible=guiVisible

	end
end)--========================      
-- HAVOC DUELS      
-- AUTO BAT + BODY AIMBOT      
--========================      

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- CONFIGURACIÓN      
local AIMBOT_RANGE = 40      
local AIMBOT_DISABLE_RANGE = 45      

local attacking = false      
local aimbotEnabled = false      
local aimbotConnection      

local alignOri      
local attach0      

-- ================= UI =================      
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "HavocDuelsUI"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 140, 0, 160)
Main.Position = UDim2.new(0.05, 0, 0.35, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true

Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1,0,0,25)
TopBar.BackgroundColor3 = Color3.fromRGB(10, 50, 120)
TopBar.BorderSizePixel = 0

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,12)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Havoc Duels"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12

-- ================= BOTONES =================
local Button = Instance.new("TextButton", Main)
Button.Size = UDim2.new(0.8,0,0,40)
Button.Position = UDim2.new(0.1,0,0,45)
Button.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
Button.Text = "🔴 AUTO BAT : OFF"
Button.TextColor3 = Color3.fromRGB(255,255,255)
Button.Font = Enum.Font.GothamBold
Button.TextSize = 11
Button.AutoButtonColor = false

Instance.new("UICorner", Button).CornerRadius = UDim.new(0,10)

local AutoBatActiveColor = Color3.fromRGB(50,200,120)

local AimbotBtn = Instance.new("TextButton", Main)
AimbotBtn.Size = UDim2.new(0.8,0,0,40)
AimbotBtn.Position = UDim2.new(0.1,0,95)
AimbotBtn.BackgroundColor3 = Color3.fromRGB(50,120,200)
AimbotBtn.Text = "🎯 AIMBOT : OFF"
AimbotBtn.TextColor3 = Color3.fromRGB(255,255,255)
AimbotBtn.Font = Enum.Font.GothamBold
AimbotBtn.TextSize = 11
AimbotBtn.AutoButtonColor = false

Instance.new("UICorner", AimbotBtn).CornerRadius = UDim.new(0,10)

local AimbotActiveColor = Color3.fromRGB(250,150,50)

local function hoverEffect(button)
	button.MouseEnter:Connect(function()
		TweenService:Create(button,TweenInfo.new(0.15),{
			BackgroundColor3 = Color3.fromRGB(85,85,85)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		if button == Button then
			local color = attacking and AutoBatActiveColor or Color3.fromRGB(50,120,200)
			TweenService:Create(button,TweenInfo.new(0.15),{BackgroundColor3=color}):Play()
		else
			local color = aimbotEnabled and AimbotActiveColor or Color3.fromRGB(50,120,200)
			TweenService:Create(button,TweenInfo.new(0.15),{BackgroundColor3=color}):Play()
		end
	end)
end

hoverEffect(Button)
hoverEffect(AimbotBtn)

-- ================= SONIDOS =================      
local OnSound = Instance.new("Sound",ScreenGui)
OnSound.SoundId="rbxassetid://8745692251"
OnSound.Volume=1

local ASound = Instance.new("Sound",ScreenGui)
ASound.SoundId="rbxassetid://5419098670"
ASound.Volume=1

-- ================= AUTO BAT =================      
local function equipBat()
	local char=player.Character
	if not char then return end

	local hum=char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local bat=player.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
	if bat then
		hum:EquipTool(bat)
		return bat
	end
end

local function autoAttack()
	task.spawn(function()
		while attacking do
			local bat=equipBat()
			if bat then
				pcall(function()
					bat:Activate()
				end)
			end
			task.wait(0.15)
		end
	end)
end

-- ================= BODY AIMBOT =================      
local function getClosestTarget()

	local char=player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local hrp=char.HumanoidRootPart
	local closest=nil
	local shortest=AIMBOT_RANGE

	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local target=plr.Character.HumanoidRootPart
			local dist=(target.Position-hrp.Position).Magnitude

			if dist<=shortest then
				shortest=dist
				closest=target
			end
		end
	end
	return closest
end

local function startBodyAimbot()

	if aimbotConnection then return end

	local char=player.Character
	if not char then return end

	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local humanoid=char:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.AutoRotate=false end

	attach0=Instance.new("Attachment",hrp)

	alignOri=Instance.new("AlignOrientation")
	alignOri.Attachment0=attach0
	alignOri.Mode=Enum.OrientationAlignmentMode.OneAttachment
	alignOri.RigidityEnabled=true
	alignOri.MaxTorque=math.huge
	alignOri.Responsiveness=200
	alignOri.Parent=hrp

	aimbotConnection=RunService.RenderStepped:Connect(function()

		local target=getClosestTarget()
		if not target then return end

		local dist=(target.Position-hrp.Position).Magnitude
		if dist>AIMBOT_DISABLE_RANGE then return end

		local lookPos=Vector3.new(target.Position.X,hrp.Position.Y,target.Position.Z)
		alignOri.CFrame=CFrame.lookAt(hrp.Position,lookPos)

	end)
end

local function stopBodyAimbot()

	if aimbotConnection then
		aimbotConnection:Disconnect()
		aimbotConnection=nil
	end

	if alignOri then alignOri:Destroy() alignOri=nil end
	if attach0 then attach0:Destroy() attach0=nil end

	local char=player.Character
	if char then
		local humanoid=char:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.AutoRotate=true end
	end
end

-- ================= BUTTONS =================      
Button.MouseButton1Click:Connect(function()

	attacking=not attacking

	if attacking then
		OnSound:Play()
		Button.Text="🟢 AUTO BAT : ON"
		Button.BackgroundColor3=AutoBatActiveColor
		autoAttack()
	else
		ASound:Play()
		Button.Text="🔴 AUTO BAT : OFF"
		Button.BackgroundColor3=Color3.fromRGB(50,120,200)
	end

end)

AimbotBtn.MouseButton1Click:Connect(function()

	aimbotEnabled=not aimbotEnabled

	if aimbotEnabled then
		OnSound:Play()
		AimbotBtn.Text="🟢 AIMBOT : ON"
		AimbotBtn.BackgroundColor3=AimbotActiveColor
		startBodyAimbot()
	else
		ASound:Play()
		AimbotBtn.Text="🎯 AIMBOT : OFF"
		AimbotBtn.BackgroundColor3=Color3.fromRGB(50,120,200)
		stopBodyAimbot()
	end

end)

-- ================= HOTKEYS =================
UserInputService.InputBegan:Connect(function(input,gpe)

	if gpe then return end

	if input.KeyCode==Enum.KeyCode.R then
		Button:Activate()
	end

	if input.KeyCode==Enum.KeyCode.T then
		AimbotBtn:Activate()
	end

end)
