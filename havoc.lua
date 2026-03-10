local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer

getgenv().AUTO_SETTINGS = getgenv().AUTO_SETTINGS or {
	TRACK = 55,
	IDA = 56,
	VOLTA = 30
}

local SPEED_TRACK = getgenv().AUTO_SETTINGS.TRACK
local SPEED_IDA   = getgenv().AUTO_SETTINGS.IDA
local SPEED_VOLTA = getgenv().AUTO_SETTINGS.VOLTA

local SPEED_A1_P2_1 = 35
local SPEED_A1_P2_2 = 30
local SPEED_B2_FINAL = 35

local PAUSE = 0.008
local DIST = 1.8
local STOP = 0.3

local A1_P1 = Vector3.new(-471.81,-7.03,95)
local A1_P2 = Vector3.new(-489.10,-4.56,95.45)
local A1_P3 = Vector3.new(-471.89,-6.56,6.31)

local B1 = Vector3.new(-474.09,-6.94,26.52)
local B2 = Vector3.new(-491.03,-4.88,24.90)
local B3 = Vector3.new(-470.80,-6.48,113.21)

local function hrp(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(c) return c and c:FindFirstChildOfClass("Humanoid") end

local gui = Instance.new("ScreenGui", lp.PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,190,0,90)
frame.Position = UDim2.new(0,20,0.5,-45)
frame.BackgroundColor3 = Color3.fromRGB(20,120,255)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

-- Ocean gradient
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,120,255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,180,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0,90,200))
}
gradient.Rotation = 45
gradient.Parent = frame

-- Frame glow
local glow = Instance.new("UIStroke")
glow.Color = Color3.fromRGB(0,200,255)
glow.Thickness = 2
glow.Parent = frame

task.spawn(function()
	local t = 0
	while true do
		t += 0.01
		gradient.Offset = Vector2.new(math.sin(t)*0.35, math.cos(t)*0.35)
		glow.Transparency = 0.25 + math.sin(tick()*2)*0.2
		task.wait(0.03)
	end
end)

-- 🔵 BLUE BUTTON STYLE
local function styleBlueButton(btn)

	btn.BackgroundColor3 = Color3.fromRGB(0,140,255)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,10)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0,200,255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25
	stroke.Parent = btn

	task.spawn(function()
		while btn.Parent do
			stroke.Transparency = 0.2 + math.sin(tick()*2)*0.2
			task.wait(0.05)
		end
	end)

end

local dragging, dragStart, startPos
frame.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = i.Position
		startPos = frame.Position
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = i.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset + d.X,startPos.Y.Scale,startPos.Y.Offset + d.Y)
	end
end)

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1,-20,0,42)
startBtn.Position = UDim2.new(0,10,0,10)
startBtn.Text = "Start Auto Play"
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 18
styleBlueButton(startBtn)

local settings = Instance.new("Frame", frame)
settings.Size = UDim2.new(1,-10,0,300)
settings.Position = UDim2.new(0,5,0,62)
settings.BackgroundColor3 = Color3.fromRGB(0,80,170)
settings.Visible = false
settings.BorderSizePixel = 0
Instance.new("UICorner", settings).CornerRadius = UDim.new(0,14)

startBtn.MouseButton1Click:Connect(function()
	settings.Visible = not settings.Visible
	frame.Size = settings.Visible and UDim2.new(0,190,0,360) or UDim2.new(0,190,0,90)
end)

local function makeInput(txt,y,default,callback)

	local lbl = Instance.new("TextLabel", settings)
	lbl.Size = UDim2.new(1,-10,0,16)
	lbl.Position = UDim2.new(0,5,0,y)
	lbl.Text = txt
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.BackgroundTransparency = 1

	local box = Instance.new("TextBox", settings)
	box.Size = UDim2.new(1,-10,0,24)
	box.Position = UDim2.new(0,5,0,y+16)
	box.Text = tostring(default)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	box.TextColor3 = Color3.new(1,1,1)
	box.BackgroundColor3 = Color3.fromRGB(0,140,255)
	box.BorderSizePixel = 0
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)

	box.FocusLost:Connect(function()
		local v = tonumber(box.Text)
		if v then callback(v) else box.Text = tostring(default) end
	end)
end

makeInput("Speed Tracked",0,SPEED_TRACK,function(v) SPEED_TRACK=v end)
makeInput("Speed Start",38,SPEED_IDA,function(v) SPEED_IDA=v end)
makeInput("Speed Stealing",76,SPEED_VOLTA,function(v) SPEED_VOLTA=v end)

local saveBtn = Instance.new("TextButton", settings)
saveBtn.Size = UDim2.new(1,-10,0,30)
saveBtn.Position = UDim2.new(0,5,0,118)
saveBtn.Text = "Save Settings"
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 14
styleBlueButton(saveBtn)

local locked = false
local lockConn

local lockBtn = Instance.new("TextButton", settings)
lockBtn.Size = UDim2.new(1,-10,0,32)
lockBtn.Position = UDim2.new(0,5,0,158)
lockBtn.Text = "TRACKED LOCK"
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 14
styleBlueButton(lockBtn)

local auto1 = false
local btnAuto1 = Instance.new("TextButton", settings)
btnAuto1.Size = UDim2.new(1,-10,0,28)
btnAuto1.Position = UDim2.new(0,5,0,200)
btnAuto1.Text = "AUTO PLAY 1"
btnAuto1.Font = Enum.Font.GothamBold
btnAuto1.TextSize = 14
styleBlueButton(btnAuto1)

local auto2 = false
local btnAuto2 = btnAuto1:Clone()
btnAuto2.Text = "AUTO PLAY 2"
btnAuto2.Position = UDim2.new(0,5,0,234)
btnAuto2.Parent = settings
styleBlueButton(btnAuto2)
