repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

pcall(function() PlayerGui:FindFirstChild("HAVOC_FINAL_BOSS_CINEMATIC"):Destroy() end)

-- Main GUI
local gui = Instance.new("ScreenGui")
gui.Name = "HAVOC_FINAL_BOSS_CINEMATIC"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,250,0,350)
frame.Position = UDim2.new(0.35,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(15,10,25)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

-- Neon border
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 3

-- Animated galaxy background
local bg = Instance.new("Frame", frame)
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(5,5,15)
bg.BorderSizePixel = 0
Instance.new("UICorner", bg).CornerRadius = UDim.new(0,16)

local particles = {}
for i=1,60 do
	local p = Instance.new("Frame")
	p.Size = UDim2.new(0,2,0,2)
	p.Position = UDim2.new(math.random(),0,math.random(),0)
	p.BackgroundColor3 = Color3.fromRGB(255,255,255)
	p.BackgroundTransparency = math.random()*0.8
	p.BorderSizePixel = 0
	p.Parent = bg
	table.insert(particles,p)
end

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,45)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Text = "HAVOC HUB DUEL HELPER"
title.TextColor3 = Color3.new(1,1,1)

-- FPS/Ping
local counter = Instance.new("TextLabel", gui)
counter.Size = UDim2.new(0,180,0,25)
counter.Position = UDim2.new(0,10,0,10)
counter.BackgroundTransparency = 1
counter.Font = Enum.Font.GothamBold
counter.TextScaled = true
counter.TextColor3 = Color3.new(1,1,1)
RunService.RenderStepped:Connect(function(dt)
	local fps = math.floor(1/dt)
	local ping = 0
	pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
	counter.Text = "FPS "..fps.." | "..ping.." ms"
end)

-- Buttons
local contentFrame = Instance.new("Frame", frame)
contentFrame.Size = UDim2.new(1,-20,1,-90)
contentFrame.Position = UDim2.new(0,10,0,90)
contentFrame.BackgroundTransparency = 1
local function createButton(name,posY)
	local b = Instance.new("TextButton", contentFrame)
	b.Size = UDim2.new(0.9,0,0,35)
	b.Position = UDim2.new(0.05,0,0,posY)
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(150,40,220)
	Instance.new("UICorner", b)
	return b
end
local galaxyBtn = createButton("Galaxy: OFF",0)
local starBtn = createButton("Stars: OFF",50)
local fovBtn = createButton("FOV: OFF",100)

-- Draggable
do
	local dragging=false
	local dragStart
	local startPos
	local dragInput
	frame.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true
			dragStart=input.Position
			startPos=frame.Position
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and input==dragInput then
			local delta=input.Position-dragStart
			frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
		end
	end)
end

-- K toggle
UIS.InputBegan:Connect(function(key,gp)
	if gp then return end
	if key.KeyCode==Enum.KeyCode.K then
		frame.Visible=not frame.Visible
	end
end)

-- Rainbow title + neon border
task.spawn(function()
	local hue=0
	while frame.Parent do
		hue+=0.005
		title.TextColor3=Color3.fromHSV(hue%1,1,1)
		stroke.Color=Color3.fromHSV(hue%1,0.8,1)
		RunService.RenderStepped:Wait()
	end
end)

-- Galaxy toggle
local galaxy=false
galaxyBtn.MouseButton1Click:Connect(function()
	galaxy=not galaxy
	if galaxy then
		Lighting.Ambient=Color3.fromRGB(90,0,180)
		Lighting.OutdoorAmbient=Color3.fromRGB(120,0,255)
	else
		Lighting.Ambient=Color3.new(.5,.5,.5)
	end
	galaxyBtn.Text="Galaxy: "..(galaxy and "ON" or "OFF")
end)

-- Shooting stars with glow trails
local stars=false
local function star()
	local char=player.Character
	if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local p=Instance.new("Part")
	p.Anchored=true
	p.CanCollide=false
	p.Material=Enum.Material.Neon
	p.Color=Color3.new(1,1,1)
	p.Size=Vector3.new(.5,.5,6)
	p.Parent=workspace
	p.Position=root.Position+Vector3.new(math.random(-200,200),200,math.random(-200,200))
	-- Trail
	local t=Instance.new("Trail",p)
	t.Lifetime=0.4
	t.Attachment0=Instance.new("Attachment",p)
	t.Attachment1=Instance.new("Attachment",p)
	t.Color=ColorSequence.new(Color3.fromRGB(255,255,255))
	t.Transparency=NumberSequence.new(0.5,1)
	local life=0
	local con
	con=RunService.RenderStepped:Connect(function(dt)
		life+=dt
		p.Position+=Vector3.new(-70,-9,-70)*dt
		if life>2 then con:Disconnect(); p:Destroy() end
	end)
end
starBtn.MouseButton1Click:Connect(function()
	stars=not stars
	starBtn.Text="Stars: "..(stars and "ON" or "OFF")
	if stars then task.spawn(function() while stars do star() task.wait(3) end end) end
end)

-- FOV toggle
local camera=workspace.CurrentCamera
local fov=false
fovBtn.MouseButton1Click:Connect(function()
	fov=not fov
	camera.FieldOfView=fov and 110 or 70
	fovBtn.Text="FOV: "..(fov and "ON" or "OFF")
end)

-- Snowflakes with glow trails
local snowflakes={}
for i=1,25 do
	local flake=Instance.new("Frame")
	flake.Size=UDim2.new(0,math.random(2,4),0,math.random(2,4))
	flake.BackgroundColor3=Color3.fromRGB(255,255,255)
	flake.BackgroundTransparency=math.random()*0.7
	Instance.new("UICorner",flake)
	flake.Position=UDim2.new(math.random(),0,0,0)
	flake.Parent=frame
	-- Glow trail
	local t=Instance.new("UIStroke",flake)
	t.Transparency=0.7
	t.Color=Color3.fromRGB(255,255,255)
	t.Thickness=2
	table.insert(snowflakes,flake)
end

RunService.RenderStepped:Connect(function(dt)
	for _,flake in pairs(snowflakes) do
		local newY=flake.Position.Y.Offset + dt*40
		if newY>frame.AbsoluteSize.Y then newY=0; flake.Position=UDim2.new(math.random(),0,0,newY)
		else flake.Position=UDim2.new(flake.Position.X.Scale,0,0,newY) end
	end
	for _,p in pairs(particles) do
		local newY=p.Position.Y.Scale+dt*0.03
		if newY>1 then p.Position=UDim2.new(math.random(),0,0,0)
		else p.Position=UDim2.new(p.Position.X.Scale,0,newY,0) end
	end
end)

-- Smooth open
frame.Size=UDim2.new(0,0,0,0)
TweenService:Create(frame,TweenInfo.new(.5,Enum.EasingStyle.Back),{Size=UDim2.new(0,250,0,350)}):Play()
